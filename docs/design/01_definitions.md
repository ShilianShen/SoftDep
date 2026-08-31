## Definitions

First, there are several basic concepts to define:

- data, just data
- task, something to do, with no responsibility for storing data
- access, a task's permission to access data

There are several kinds of dependencies.

### Control Dependency

$$
E_c\subseteq \mathcal{T}\times \mathcal{T}
$$

where $(\mathcal{T}, E_c)$ is a DAG.

For $(a,b)\in E_c$, we say that $b$ depends on $a$.

### Data Dependency

$$
E_d\subseteq \mathcal{D}\times \mathcal{T}
$$

For $(d, t)\in E_d$, we say that $t$ depends on $d$.

### Parents and Children

$$
\mathop{\text{parents}}_i(x)=\{p|(p, x)\in E_i\}
$$

$$
\mathop{\text{children}}_i(x)=\{c|(x, c)\in E_i\}
$$

### Path

For $a,b\in \mathcal{T}$, if $a\neq b$ and there is a path in $(\mathcal{T}, E_c)$ from $a$ to $b$, we write $a\leadsto b$.

### Restriction Notation

For a binary relation $R$ and a set $X$, we denote the restriction of $R$ to $X$ by

$$
R|_X=R\cap(X\times X)
$$

### Order

$<_T\subseteq T\times T, T\subseteq \mathcal{T}$ satisfies the following properties:

- $(T, <_T)$ is a strict total order.
- $\forall (a,b)\in E_c|_T: a<_T b$

Hereafter, all orders are assumed to be topological orders.

$$
O(T)=\{<_T\subseteq T\times T|(T, <_T)\ \text{is a topological order}\}
$$

### Parallel Tasks

$$
\mathop{\text{parallel}}(d) = \{
T\subseteq \mathop{\text{children}}_d(d)\mid
\forall a,b\in T: \neg(a\leadsto b\lor b\leadsto a)
\}
$$

Every ordering of the tasks in $T$ can be extended to a topological ordering of the entire task graph.

$$
\forall <_T\in O(T), \exists <\in O(\mathcal{T})\ <_T = <|_T \\
$$

Because there is no path in $T$ we have $|O(T)|=|T|!$.

### Access

$$
\mathop{\text{access}}: E_d\to A
$$

We use $\mathop{\text{access}}(d,t)$ as shorthand for $\mathop{\text{access}}((d,t))$.

---

$A^\circ$ is the set of available access levels determined by the environment in which SoftDep is used.

$(A^\circ, \le)$ is a partially ordered set satisfying the following properties:

- $\{\bot, \top\}\subseteq A^\circ$
- $\forall a\in A^\circ:\bot\le a\le\top$

For $a, b\in A^\circ$ with $a<b$, we say that $b$ is a higher access level than $a$.

---

$A=\mathop{\text{DM}}(A^\circ)$ is the Dedekind–MacNeille completion of $A^\circ$.

Thus, $(A, \le)$ satisfies the following properties:

- $(A, \le)$ is a complete lattice.
- $\forall B\subseteq A$ both $\bigvee_{a\in B}a$ and $\bigwedge_{a\in B}a$ exist.

---

A task can be considered a list of operations or smaller tasks $t = (t_1, \dots, t_n)$. In this case, we can determine the minimum access level required by $t$:

$$
\mathop{\text{access}}(d, t)=\bigvee_{i\le |t|}\mathop{\text{access}}(d, t_i)
$$

Sometimes, it is useful to consider multiple tasks as a single task. In this way, the minimum access level required by any task group can be determined.

### Dirty

$$
\mathop{\text{dirty}}:\mathcal{T}\to\mathbb{B}
$$

$$
\mathop{\text{dirty}}_{i+1}(t)=\mathop{\text{dirty}}_i(t)\lor(\exists p\in \mathop{\text{parents}}_c(t):\mathop{\text{dirty}}_i(p))
$$

The sequence $\{\mathop{\text{dirty}}_i\}_{i\ge 0}$ takes at least $|\mathcal{T}|$ steps to reach the final value.
