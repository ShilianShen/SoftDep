package.path = "src/?.lua;src/?/init.lua;" .. package.path

local softdep = require("softdep")

local function identity(data)
	return data
end

local function input()
	return {
		tasks = {
			changed = {},
		},
		apis = {
			set = {
				ttag = "changed",
				func = function(data, value)
					data.value = value
				end,
			},
		},
	}
end

local graph = softdep.newGraph({
	access = {
		levels = {
			read = {
				func = identity,
				os = false,
			},
			write = {
				func = identity,
				os = true,
			},
		},
		lt = {
			{ "read", "write" },
		},
	},

	default = {
		nodeAtag = "read",
		taskAtag = "write",
	},

	nodes = {
		price = input(),
		quantity = input(),
		taxRate = input(),

		subtotal = {
			tasks = {
				compute = {
					parents_d = {
						price = "price",
						quantity = "quantity",
					},
					func = function(data, parents)
						data.value = parents.price.value * parents.quantity.value
						print("compute subtotal:", data.value)
					end,
				},
			},
		},

		tax = {
			tasks = {
				compute = {
					parents_d = {
						subtotal = "subtotal",
						taxRate = "taxRate",
					},
					func = function(data, parents)
						data.value = parents.subtotal.value * parents.taxRate.value
						print("compute tax:", data.value)
					end,
				},
			},
		},

		total = {
			tasks = {
				compute = {
					parents_d = {
						subtotal = "subtotal",
						tax = "tax",
					},
					func = function(data, parents)
						data.value = parents.subtotal.value + parents.tax.value
						print("compute total:", data.value)
					end,
				},
			},
		},
	},
})

-- Set the initial values.
graph.nodes.price.apis.set(20)
graph.nodes.quantity.apis.set(3)
graph.nodes.taxRate.apis.set(0.1)

graph:run()

print("total:", graph.nodes.total.data.value)

print("\nchange tax rate\n")

-- Only `tax` and `total` need to be recomputed.
graph.nodes.taxRate.apis.set(0.2)
graph:run()

print("total:", graph.nodes.total.data.value)
