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

$sort: tasks\to\{1,\dots,|tasks|\}$ is a bijection satisfying $\forall (a,b)\in deps_c:sort(a) < sort(b)$.

$sorts$ is the set of all possible topological orderings.

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

## Parallel Tasks of Data

$$
parallel:data\to\mathcal{P}(\mathcal{P}(tasks))
$$

$\mathcal{T}=parallel(d)$ is a family of sets, where each $T\in\mathcal{T}$ satisfies the following properties:

- For every $a, b\in T$ there is no path from $a$ to $b$ or from $b$ to $a$ in $(tasks, deps_c)$.
- $\forall t\in T, \exists (d, t)\in deps_d$

## Access

$$
deps_a: deps_d\to access
$$

We use $deps_a(d,t)$ as shorthand for $deps_a((d,t))$.

---

$access^\circ$ is the set of available access levels determined by the environment in which SoftTree is used.

$(access^\circ, \le)$ is a partially ordered set satisfying the following properties:

- $\{\bot, \top\}\subseteq access^\circ$
- $\forall a\in access^\circ:\bot\le a\le\top$

For $a, b\in access^\circ$ with $a<b$, we say that $b$ is a higher access level than $a$.

---

$access=DM(access^\circ)$ is the Dedekind–MacNeille completion of $access^\circ$.

Thus, $(access, \le)$ satisfies the following properties:

- $(access, \le)$ is a complete lattice.
- $\forall A\subseteq access$ both $\bigvee_{a\in A}a$ and $\bigwedge_{a\in A}a$ exist.

---

A task can be considered a list of operations or smaller tasks $t = (t_1, \dots, t_n)$. In this case, we can determine the minimum access level required by $t$

$$
deps_a(d, t)=\bigvee_{i\le |t|}deps_a(d, t_i)
$$

Sometimes, it is useful to consider multiple tasks as a single task. In this way, the minimum access level required by any task group can be determined.
