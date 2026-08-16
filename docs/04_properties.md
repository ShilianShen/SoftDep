# Design - Properties

## Conflict among multiple tasks

For each data item $d_i$ we can split the $children_d(d_i)$ in two parts $T_i$ and $\overline{T_i}:=children_d(d_i)\setminus T_i$.

Because of node order there is $\forall a\in T_i,\forall b\in\overline{T_i}:a< b$.

Thus $\forall T\in parallel(d):T\subseteq T_i\veebar T\subseteq\overline{T_i}$.

---

Case 1, $T\subseteq T_i$

$$
\begin{aligned}
\because & |O(T_i)| = 1\\
\therefore & \forall (T:T\in parallel(d_i)\land T\subseteq T_i):|T| = 1
\end{aligned}
$$

---

Case 2, $T\subseteq \overline{T_i}$

$$
\begin{aligned}
\because & |O(T_i)| = 1\\
\therefore & \forall (T:T\in parallel(d_i)\land T\subseteq T_i):|T| = 1
\end{aligned}
$$

---

$$
\exists d\in data, 
\exists T\in parallel(d):
\left(
    \bigvee_{t\in T}access(d, t)\ge OS
\right)
\land (|T|>1)
$$
