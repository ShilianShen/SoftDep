## Properties

### Conflict among multiple tasks

For each data item $d_i$ we can split the $children_d(d_i)$ in two parts $T_i$ and $\overline{T_i}:=children_d(d_i)\setminus T_i$.

Because of node order there is $\forall a\in T_i,\forall b\in\overline{T_i}:a< b$.

Thus $\forall T\in parallel(d):T\subseteq T_i\veebar T\subseteq\overline{T_i}$.

---

Case 1, $T\subseteq T_i$

$$
\begin{aligned}
    \because & \forall T\in parallel(d),\forall <_T\in O(T),\exists <_{T_i}\in O(T_i): <_T=<_{T_i}|_T 
    \\
    & |O(T_i)|=1
    \\
    \therefore & \forall T\in parallel(d),|O(T)|\le|O(T_i)| = 1
    \\
    \because & |O(T)|=|T|!= 1
    \\
    \therefore & |T| = 1
\end{aligned}
$$

---

Case 2, $T\subseteq \overline{T_i}$

$$
\begin{aligned}
    \because & T\subseteq\overline{T_i}
    \\
    \therefore & \bigvee_{t\in T}access(d_i,t)\le\bigvee_{t\in \overline{T_i}}access(d_i,t)\le a< OS
\end{aligned}
$$

---

Thus,

$$
\forall d\in data, 
\forall T\in parallel(d):
\left(
    \bigvee_{t\in T}access(d, t)< OS
\right)
\lor (|T|\le1)
$$

Therefore, there is no conflict.
