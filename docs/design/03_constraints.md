## Constraints

### Split the Task

Each task can have an access level greater than or equal to order-sensitive for at most one data item.

$$
\forall t\in \mathcal{T}:\sum_{d\in \operatorname{parents}_d(t)}\mathbb{1}[\operatorname{access}(d, t)\ge \mathrm{OS}]\le 1
$$

If an existing task does not satisfy this property, it can be split into smaller tasks that do.

### Encapsulation

$$
(\mathcal{N}, E_n)
$$

Each $n=(d, T, a)\in \mathcal{N}$ satisfies the following properties:

- $d\in \mathcal{D}, T\subseteq \mathcal{T}$
- $\forall t\in \mathcal{T}:((d, t)\in E_d \land \operatorname{access}(d, t)\ge \mathrm{OS})\to t\in T$
- $a\in A, \bigvee_{(d, t)\in E_d,t\notin T} \operatorname{access}(d,t)\le a<\mathrm{OS}$

For convenience, we use subscripts to indicate the relationships among $n$, $d$, $T$, and $t$. Variables sharing the same subscript satisfy the relations $n_i=(d_i, T_i, a_i)$ and $t_i\in T_i$.

$\mathcal{N}$ satisfies the following properties:

- $\{d|(d, T, a)\in \mathcal{N}\}=\mathcal{D}$
- $\bigcup_{(d, T, a)\in \mathcal{N}}T=\mathcal{T}$
- $\forall n_1, n_2 \in \mathcal{N}, n_1\neq n_2: T_1\cap T_2=\varnothing, d_1\neq d_2$

$E_n \subseteq \mathcal{N}\times \mathcal{N}$ satisfies the following properties:

- $\forall n_1,n_2\in \mathcal{N}:(n_1,n_2)\in E_n\leftrightarrow n_1\neq n_2\land \exists (t_1, t_2)\in E_c$

### DAG Constraint

The strongest constraint of SoftDep is that $(\mathcal{N}, E_n)$ must also be a DAG.

Note that this constraint cannot be derived from the previous definitions.

### Local Total Ordering

This constraint requires $E_c$ to satisfy the following property:

$$
\forall n_i\in \mathcal{N}:|O(T_i)|=1
$$

In other words, no two tasks in $T_i$ are parallel.

### Node Order

Because $(\mathcal{N}, E_n)$ is a DAG, there is also a topological order $<_N$.

$E_c$ is required to satisfy the following properties:

- $\forall <\in O(\mathcal{T}),\forall t_1\in T_1, \forall t_2\in T_2:n_1<_Nn_2\to t_1<t_2$

### Backward Node

$$
n_b
$$

This node is introduced to address the problem that nodes cannot affect parent nodes in $(\mathcal{N}, E_n)$.

We call it a "node" because it has properties similar to those of normal nodes.

$n_b$ satisfies the following properties:

- $n_b\notin \mathcal{N}$
- $d_b\notin \mathcal{D}$
- $T_b\cap \mathcal{T} = \varnothing$
- The tasks in $n_b$ can read and write any data item.

Some tasks $t_b\notin \mathcal{T}$ cannot belong to any node in $\mathcal{N}$ because of the DAG constraint, but they can belong to $n_b$.

The tasks in $n_b$ are executed after all other tasks.
