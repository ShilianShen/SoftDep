## Inducing

Define

$$
\begin{cases}
    \delta^-_{c,i}:=\delta^-_c|_{T_i\to T_i\times T_i} \\
    \delta^-_{d,i}:=\delta^-_d|_{T_i\to \mathcal{D}\times T_i} \\
    \mathop{\text{access}}_i:=\mathop{\text{access}}|_{\{d_i\}\times T_i\to A} \\
\end{cases}
$$

$$
\begin{pmatrix}
    \mathcal{N} \\
    \{d_i|n_i\in\mathcal{N}\} \\
    \{T_i|n_i\in\mathcal{N}\} \\
    \{\delta^-_{d,i}|n_i\in\mathcal{N}\} \\
    \{\delta^-_{c,i}|n_i\in\mathcal{N}\} \\
    \{\mathop{\text{access}}_i|n_i\in\mathcal{N}\} \\
\end{pmatrix}
\to
\begin{pmatrix}
    \mathcal{D} \\
    \mathcal{T} \\
    E_d \\
    E_c \\
    \mathop{\text{access}} \\
\end{pmatrix}
$$

$$
\begin{aligned}
\mathcal{D} &= {d_i|n_i\in\mathcal{N}} \\
\mathcal{T} &= \bigcup_{n_i\in\mathcal{N}}T_i \\
E_d &= \bigcup_{n_i\in\mathcal{N}} \delta^-_{d,i}(n_i) \\
E_c &=
    \bigcup_{n_i\in\mathcal{N}}
        \delta^-_{c,i}(n_i)
    \cup
    \bigcup_{(d_i,t)\in E_d}
        \{(t_i, t)|t_i\in T_i, t\notin T_i\mathop{\text{access}}(d_i,t_i)\ge\mathrm{OS}\}
    \\
\mathop{\text{access}} &=
    \bigcup_{n_i\in\mathcal{N}}
        \mathop{\text{access}}_i
    \cup
    \bigcup_{(d_i, t)\in E_d}
        \{(d_i,t)\to a_i|t\notin T_i\}
\end{aligned}
$$
