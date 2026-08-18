## Problems

### Conflict among multiple tasks

```mermaid
graph
    taskA[A: a=0]
    taskB[B: a++]
    taskC["C: print(a)"]

    taskA --> taskB
    taskA --> taskC
```

In this case the output may be unpredictable, because $(A, B, C)$ and $(A, C, B)$ both satisfy the order condition of Control Dependency.

This problem can occur when a data item has multiple dependent tasks that have no control dependency between them.

But multiple dependent tasks do not always cause this problem.

Assume that $A$ contains the following access levels:

- $\mathrm{OS}$: order-sensitive
- $\mathrm{RO}$: readonly. Example: `print`
- $\mathrm{OISW}$: order-insensitive write without read, meaning that for a data item $d$ and two tasks $a, b$ with $\operatorname{access}(d, a), \operatorname{access}(d, b)\le \mathrm{OISW}$, the results of $(a, b)$ and $(b, a)$ are the same. Example: `x++`

Obviously, these access levels satisfy $\mathrm{OS} = \mathrm{RO}\vee \mathrm{OISW}$.

The problem happens if and only if

$$
\exists d\in \mathcal{D},
\exists T\in \operatorname{parallel}(d):
\left(
    \bigvee_{t\in T}\operatorname{access}(d, t)\ge \mathrm{OS}
\right)
\land (|T|>1)
$$

When the combined access level is order-sensitive, there must be an explicit order to decide which task executes first. But specifying the order explicitly is cumbersome, so we need another approach.

### Poor Extensibility

If a new task is added to the system, it could cause new conflicts or invalidate the existing structure.

```mermaid
graph
    A[A: old task]
    B[B: old task]
    C[C: new task]
    A --> B
    A -.-> C -.-> B
```
