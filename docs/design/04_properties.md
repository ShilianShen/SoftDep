## Properties

### No more conflict among multiple tasks

For each data item $d_i$ we can split the $\operatorname{children}_d(d_i)$ in two parts $T_i$ and $\overline{T_i}:=\operatorname{children}_d(d_i)\setminus T_i$.

Because of node order there is $\forall a\in T_i,\forall b\in\overline{T_i}:a< b$.

Thus $\forall T\in \operatorname{parallel}(d):T\subseteq T_i\lor T\subseteq\overline{T_i}$.

---

Case 1, $T\subseteq T_i$

$$
\begin{aligned}
    \because & \forall T\in \operatorname{parallel}(d),\forall <_T\in O(T),\exists <_{T_i}\in O(T_i): <_T=<_{T_i}|_T
    \\
    & |O(T_i)|=1
    \\
    \therefore & \forall T\in \operatorname{parallel}(d),|O(T)|\le|O(T_i)| = 1
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
    \therefore & \bigvee_{t\in T}\operatorname{access}(d_i,t)\le\bigvee_{t\in \overline{T_i}}\operatorname{access}(d_i,t)\le a_i< \mathrm{OS}
\end{aligned}
$$

---

Thus,

$$
\forall d\in \mathcal{D},
\forall T\in \operatorname{parallel}(d):
\left(
    \bigvee_{t\in T}\operatorname{access}(d, t)< \mathrm{OS}
\right)
\lor (|T|\le1)
$$

Therefore, there is no conflict.

### Better Extensibility

For every $X\subseteq \mathcal{N}:\delta^-(X)=\varnothing$, $(X, E_n|_X)$ is also a DAG.

In this case, $(\mathcal{N}, E_n)$ can be considered as an extension of $(X, E_n|_X)$.

Obviously, in this structure, extension can't affect the system before.

Therefore, it's easy to extend an existing system.
