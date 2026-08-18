```mermaid
erDiagram
    graph {
        Ntag-Node nodes
        Func[] funcs
        Ntag[] nodeOrder
        Task[] taskOrder
        Bool dirty
    }
    node {
        Data data
        Ttag-Task tasks
        Access access
        Ttag[] taskOrder
        Ntag[] deps
        Bool dirty
    }
    task {
        Func func
        Atag-Ntag args
        Ttag[] deps
        Bool dirty
        Access access
    }

    graph ||--|{ node : "graph.nodes[ntag]=node"
    node ||--|{ task : "node.tasks[ttag]=task"
```