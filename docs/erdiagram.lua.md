```mermaid
erDiagram
    graph {
        Ntag-Node nodes
        Func extend
        Func tick
        Ntag[] nodeOrder
    }
    node {
        Data data
        Ttag-Task tasks
        Access access
        Ttag[] taskOrder
        Ntag[] nodeDeps
    }
    task {
        Func func
        Atag-Ntag args
        Ttag[] taskDeps
        Bool dirty
    }

    graph ||--|{ node : "graph.nodes[ntag]=node"
    node ||--|{ task : "node.tasks[ttag]=task"
```