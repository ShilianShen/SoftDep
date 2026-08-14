# Design - Solution

## What does SoftTree do?

### Split the Task

Each task can have an access level greater than or equal to writable for at most one data item.

$$
\forall t\in tasks:\sum_{d\in parents_d(t)}\mathbb{1}[deps_a(d, t)\ge writable]\le 1
$$

If an existing task does not satisfy this property, it can be split into smaller tasks that do.

### OOP

#### Belonging

Define

$$
deps_b:tasks\to data
$$

such that

$$
deps_a(d, t)\ge writable\rightarrow deps_b(t) = d
$$

If $deps_b(task)=d$, we say that $t$ belongs to $d$.

---

$$
tasks_d := \{task|task\in tasks,deps_b(task)=d\} \\
node_d := (d, tasks_d)
$$

#### 封装依赖

$$
deps_e \subseteq nodes\times nodes \\
$$

$$
\begin{rcases}
    \exists(task_a, task_b)\in deps_c \\
    a = deps_b(task_a) \\
    b = deps_b(task_b) \\
    node_a \neq node_b
\end{rcases}
\Leftrightarrow
(node_a, node_b) \in deps_e
$$

### DAG约束

SoftTree最大的约束是, $(nodes, deps_e)$ 也应该为DAG.

这个约束并不能从前面的情景推导得到, 而是为了解决问题而针对用户提出的限制.

而且某种意义上两个nodes之间有task反复依赖也挺怪的.

### 反向node

目前的SoftTree的一个缺点是, 子节点无法write影响父节点.

这里给出的方法是, 设定有且仅有一个脱离前文管理的节点, 就是反向节点

- 反向节点可以read所有其他的节点, 并且其他节点无法知道反向节点存在
- 反向节点可以write所有其他的节点

原本以为DAG约束, 而无法实现的task, 可以在反向节点里实现.

## SoftTree的优点

- 多task的冲突只会发生在单个模块之间, 可以直接手动串联解决
- 增强扩展性, 问题变成了模块之间的单向依赖的拼接
- 循环依赖问题只需要在SoftTree外排查即可知晓

## ER图 (待完善)

```mermaid
erDiagram
    tree {}
    node {}
    data {}
    task {}
    dep_a {
        Task task FK
        Data data FK
        Access access
    }

    tree ||--|{ node: "consist"
    node ||--|| data: "dep_b"
    node ||--|{ task: "dep_b"
    task ||--|{ dep_a: "dep_a"
    data ||--|{ dep_a: "dep_a"
    task ||--|{ task: ""
```

## 各个语言能实现的access (待完善)

Lua: none, readonly, writable
