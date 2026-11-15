# Diagram NN — Title of the architecture

> **Verified:** 2026-11-15 · **Type:** academy design, not an official AWS reference architecture · **Related chapters:** links

One paragraph: what architecture this set documents and the question it answers.

## A. Conceptual view

The idea in as few boxes as possible — for a reader seeing it for the first time.

```mermaid
---
title: NN-A · Title (conceptual)
---
flowchart LR
    user["Client"]:::client --> app["Your application"]:::compute
    app --> model["Amazon Bedrock"]:::ai
    model -.-> app
    app -.-> user

    classDef client  fill:#E8F1FB,stroke:#1F6FEB,color:#0B1F33
    classDef compute fill:#FDEBD0,stroke:#D97706,color:#3B2300
    classDef ai      fill:#E6F4EA,stroke:#1E8E3E,color:#0B2E13
```

**What this shows** — one paragraph.

## B. Detailed implementation view

Every component, boundary, protocol, data store and security control.

```mermaid
---
title: NN-B · Title (detailed implementation)
---
flowchart TB
    subgraph internet["Internet — untrusted"]
        user["Client application"]:::client
    end
    subgraph account["AWS account · Region"]
        subgraph vpc["VPC — private subnets"]
            fn["AWS Lambda<br/>execution role"]:::compute
            vpce["Interface VPC endpoint<br/>bedrock-runtime"]:::security
        end
        model["Amazon Bedrock Runtime"]:::ai
        store[("Amazon S3<br/>SSE-KMS")]:::data
        trail[("AWS CloudTrail")]:::obs
    end
    user -- "1. HTTPS" --> fn
    fn -- "2. Converse · TLS · SigV4" --> vpce
    vpce -- "3. AWS PrivateLink" --> model
    model -. "4. Response" .-> fn
    fn -- "5. PutObject" --> store
    model -- "6. Management events" --> trail

    subgraph legend["Legend"]
        l1["Client"]:::client
        l2["Your compute"]:::compute
        l3["Bedrock / managed AI"]:::ai
        l4[("Data store")]:::data
        l5["Security control"]:::security
        l6[("Observability")]:::obs
    end

    classDef client   fill:#E8F1FB,stroke:#1F6FEB,color:#0B1F33
    classDef compute  fill:#FDEBD0,stroke:#D97706,color:#3B2300
    classDef ai       fill:#E6F4EA,stroke:#1E8E3E,color:#0B2E13
    classDef data     fill:#EDE7F6,stroke:#6A1B9A,color:#2A0A3D
    classDef security fill:#FDECEA,stroke:#C62828,color:#3D0A0A
    classDef obs      fill:#FFF8E1,stroke:#B28704,color:#3D2E00
```

**Legend** — solid arrow: request or write · dashed arrow: response · cylinder: data at rest · nested boxes: trust and network boundaries.

### Component roles

| Component | Role in this architecture | Security control |
|:--|:--|:--|
| | | |

### Connections

| # | From → To | Protocol / operation | Direction of data | Auth |
|--:|:--|:--|:--|:--|
| 1 | | | | |

## C. Sequence view

```mermaid
---
title: NN-C · Title (execution sequence)
---
sequenceDiagram
    autonumber
    participant U as Client
    participant F as AWS Lambda
    participant B as Amazon Bedrock Runtime
    U->>F: Request
    Note over F,B: SigV4 with the function's execution role
    F->>B: Converse
    B-->>F: Response
    F-->>U: Response
```

Explain the steps, including failure paths.

## Variations

Where the real implementation differs by model, Region, API or configuration, list each
variation and what changes in the diagram.

| Variation | What changes |
|:--|:--|
| | |

## Practical example

Link to the project or chapter that implements this architecture, and name the files to read.

## References

- [Page title](https://docs.aws.amazon.com/) — what it supports in this diagram.
