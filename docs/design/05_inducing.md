## Inducing

Define

$$
\begin{cases}
    \delta^-_{c,i}:=\delta^-_c|_{T_i\to T_i\times T_i} \\
    \delta^-_{d,i}:=\delta^-_d|_{T_i\to \mathcal{D}\times T_i} \\
    \operatorname{access}_i:=\operatorname{access}|_{\{d_i\}\times T_i\to A} \\
\end{cases}
$$

$\mathcal{N}, \mathcal{D}, \mathcal{T}$ are known.

$$
\begin{pmatrix}
    \{\delta^-_{d,i}|n_i\in\mathcal{N}\} \\
    \{\delta^-_{c,i}|n_i\in\mathcal{N}\} \\
    \{\operatorname{access}_i|n_i\in\mathcal{N}\} \\
\end{pmatrix}
\to
\begin{pmatrix}
    E_d \\
    E_c \\
    E_n \\
    \operatorname{access} \\
\end{pmatrix}
$$

$$
\begin{aligned}
E_d &= \bigcup_{n_i\in\mathcal{N}} \delta^-_{d,i}(n_i) \\
E_c &=
    \bigcup_{n_i\in\mathcal{N}}
        \delta^-_{c,i}(n_i)
    \cup
    \bigcup_{(d_i,t)\in E_d}
        \{(t_i, t)|t_i\in T_i, \operatorname{access}(d_i,t_i)\ge\mathrm{OS}\}
    \\
E_n &= \{(n_1,n_2)|n_1,n_2\in\mathcal{N},n_1\neq n_2, (t_1,t_2)\in E_c\lor (d_1,t_2)\in E_d\} \\
\operatorname{access} &=
    \bigcup_{n_i\in\mathcal{N}}
        \operatorname{access}_i
    \cup
    \bigcup_{(d_i, t)\in E_d}
        \{(d_i,t)\to a_i|t\notin T_i\}
\end{aligned}
$$
