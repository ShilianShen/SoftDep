```mermaid
erDiagram
    graph {
        Ntag-Node nodes
        Func extend
        Func tick
        Ntag[] order
    }
    node {
        Data data
        Task task
        Access access
        Ttag[] order
        Ntag[] deps
    }
    task {
        Func func
        Atag-Ntag args
        Ttag[] deps
        Bool dirty
    }

    graph ||--|{ node : "graph.nodes[ntag]=node"
    node ||--|{ task : "node.tasks[ttag]=task"
```