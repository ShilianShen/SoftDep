# Design - Definitions

First, there are several basic concepts to define:

- data, just data
- task, something to do, with no responsibility for storing data
- access, a task's permission to access data

There are several kinds of dependencies.

## Control Dependency

$$
deps_c\subseteq tasks\times tasks
$$

where $(tasks, deps_c)$ is a DAG.

For $(a,b)\in deps_c$, we say that $b$ depends on $a$.

## Data Dependency

$$
deps_d\subseteq data\times tasks
$$

For $(d, t)\in deps_d$, we say that $t$ depends on $d$.

## Parents and Children

$$
parents_i(x)=\{p|(p, x)\in deps_i\}
$$

$$
children_i(x)=\{c|(x, c)\in deps_i\}
$$

## Path

For $a,b\in tasks$, if $a\neq b$ and there is a path in $(tasks, deps_c)$ from $a$ to $b$, we write $a\leadsto b$.

## Restriction Notation

For a binary relation $R$ and a set $X$, we denote the restriction of $R$ to $X$ by

$$
R|_X=R\cap(X\times X)
$$

## Order

$<_{topo, X}\subseteq X\times X, X\subseteq tasks$ satisfies the following properties:

- $(X, <_{topo, X})$ is a strict total order.
- $\forall (a,b)\in deps_c|_{X}: a<_{topo, X} b$

Hereafter, all orders are assumed to be topological orders.

## Parallel Tasks

$$
parallel(d) = \{
T\subseteq children_d(d)\mid
\forall a,b\in T: \neg(a\leadsto b\lor b\leadsto a)
\}
$$

Every ordering of the tasks in $T$ can be extended to a topological ordering of the entire task graph.

$$
\forall <_{topo, T}, \exists <_{topo}:\ <_{topo, T} = <_{topo}|_T
$$

## Access

$$
access: deps_d\to A
$$

We use $access(d,t)$ as shorthand for $access((d,t))$.

---

$A^\circ$ is the set of available access levels determined by the environment in which SoftTree is used.

$(A^\circ, \le)$ is a partially ordered set satisfying the following properties:

- $\{\bot, \top\}\subseteq A^\circ$
- $\forall a\in A^\circ:\bot\le a\le\top$

For $a, b\in A^\circ$ with $a<b$, we say that $b$ is a higher access level than $a$.

---

$A=DM(A^\circ)$ is the Dedekind–MacNeille completion of $A^\circ$.

Thus, $(A, \le)$ satisfies the following properties:

- $(A, \le)$ is a complete lattice.
- $\forall B\subseteq A$ both $\bigvee_{a\in B}a$ and $\bigwedge_{a\in B}a$ exist.

---

A task can be considered a list of operations or smaller tasks $t = (t_1, \dots, t_n)$. In this case, we can determine the minimum access level required by $t$:

$$
access(d, t)=\bigvee_{i\le |t|}access(d, t_i)
$$

Sometimes, it is useful to consider multiple tasks as a single task. In this way, the minimum access level required by any task group can be determined.
