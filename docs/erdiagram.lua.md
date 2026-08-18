```mermaid
erDiagram
    graph {
        Ntag-Node nodes
        Func[] funcs
        Node[] nodeOrder
        Task[] taskOrder
        Bool ready
    }
    node {
        Data data
        Ttag-Task tasks
        Access access
        Task[] taskOrder
        Ntag[] deps
    }
    task {
        Func func
        Atag-Ntag args
        Data data
        Atag-Data _args
        Ttag[] deps
        Bool dirty
        Access access
    }

    graph ||--|{ node : "graph.nodes[ntag]=node"
    node ||--|{ task : "node.tasks[ttag]=task"
```