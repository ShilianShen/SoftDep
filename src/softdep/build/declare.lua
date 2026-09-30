---@class softdep.declaration.Task
---@field func function|nil
---@field auto function|nil
---@field atag string|nil
---@field parents_c string[]|nil
---@field parents_d table<string, string>|nil

---@class softdep.declaration.Api
---@field func function|nil
---@field ttag string|nil
---@field atag string|nil

---@class softdep.declaration.Node
---@field atag string|nil
---@field tasks table<string, softdep.declaration.Task>|nil
---@field apis table<string, softdep.declaration.Api>|nil

---@class softdep.declaration.Graph
---@field access {levels: table<string, softdep.AccessLevel>, lt: softdep.Edges}
---@field nodes table<string, softdep.declaration.Node>|nil
---@field default {nodeAtag: string, taskAtag: string, apiAtag: string}

---@class softdep.Task
---@field func function
---@field auto function
---@field atag string
---@field dirty boolean
---@field count integer

---@class softdep.Api
---@field func function|nil
---@field ttag string|nil
---@field atag string

---@class softdep.Node
---@field tasks table<string, softdep.Task>
---@field apis table<string, softdep.Api>
---@field atag string
---@field data table
---@field data_a table<string, table>
---@field dirty boolean
---@field count integer
---@field parents_c softdep.AdjList
---@field children_c softdep.AdjList
---@field order string[]

---@class softdep.Graph
---@field access softdep.Access
---@field nodes table<string, softdep.Node>
---@field parents_n softdep.AdjList
---@field children_n softdep.AdjList
---@field order string[]
---@field parents_d table<string, table<string, table<string, string>>>
---@field children_d table<string, softdep.AdjList>

return
