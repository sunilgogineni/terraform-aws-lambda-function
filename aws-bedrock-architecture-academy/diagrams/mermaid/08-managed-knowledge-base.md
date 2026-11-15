# Diagram 08 — Managed Knowledge Base architecture

> **Verified:** 2026-11-15 · **Type:** academy design, not an official AWS reference architecture · **Related chapters:** [Managed Knowledge Base](../../01-amazon-bedrock/knowledge-bases/02-managed-knowledge-base.md) · [Knowledge Bases overview: managed versus customer-managed](../../01-amazon-bedrock/knowledge-bases/01-knowledge-bases-overview.md) · [Agentic retrieval with AgenticRetrieveStream](../../01-amazon-bedrock/agentic-retrieval/01-agentic-retrieval.md)

This set documents an Amazon Bedrock Managed Knowledge Base: the knowledge base type in which
AWS operates connectors, parsing, embedding, storage, search and reranking. It answers one
question: **what stays in your account, what runs inside the AWS-managed boundary, and which
controls sit on each line between them?** AWS does not publish the internals of the managed
storage; boxes inside the managed boundary are a conceptual model of documented behaviour.

## A. Conceptual view

```mermaid
---
title: 08-A · Managed Knowledge Base (conceptual)
---
flowchart LR
    sources[("Your data sources<br/>Amazon S3 · SaaS applications · custom")]:::data
    app["Your application or agent"]:::compute
    subgraph mkb["Amazon Bedrock Managed Knowledge Base · operated by AWS"]
        ingest["Ingest<br/>connect · parse · embed"]:::ai
        store[("Managed storage")]:::data
        search["Search<br/>hybrid · rerank · ACL filter"]:::ai
    end
    ingest -- "1. Read documents" --> sources
    ingest -- "2. Index" --> store
    app -- "3. Retrieve" --> search
    search -- "4. Query" --> store
    search -. "5. Relevant passages" .-> app

    classDef compute fill:#FDEBD0,stroke:#D97706,color:#3B2300
    classDef ai      fill:#E6F4EA,stroke:#1E8E3E,color:#0B2E13
    classDef data    fill:#EDE7F6,stroke:#6A1B9A,color:#2A0A3D
```

**What this shows** — you own two things, the sources and the caller. Everything in between is
one managed resource: it pulls documents in (1), builds and keeps an index (2), and answers
searches (3 to 5). There is no vector database for you to create, size or patch.

**Legend** — solid arrow: request or write · dashed arrow: response · cylinder: data at rest ·
orange: your compute · green: Amazon Bedrock · purple: data.

## B. Detailed implementation view

```mermaid
---
title: 08-B · Managed Knowledge Base (detailed implementation)
---
flowchart TB
    subgraph saas["Outside AWS · third-party SaaS · separate trust zone"]
        src["SharePoint · OneDrive · Google Drive<br/>Confluence · Salesforce · websites"]:::external
    end
    subgraph account["Your AWS account 111122223333 · one Region"]
        deploy["Deployment role<br/>iam:PassRole to bedrock.amazonaws.com"]:::client
        subgraph vpc["Your VPC · private subnets"]
            app["Application or agent<br/>IAM role · bedrock:Retrieve"]:::compute
            vpce["Interface VPC endpoints<br/>bedrock-agent · bedrock-agent-runtime"]:::security
        end
        bucket[("Amazon S3 bucket<br/>documents · metadata · ACL files")]:::data
        secret["AWS Secrets Manager<br/>connector credentials"]:::security
        role["Knowledge base service role<br/>trust: bedrock.amazonaws.com<br/>aws:SourceAccount · aws:SourceArn"]:::security
        key["AWS KMS customer managed key<br/>grant created by Amazon Bedrock"]:::security
        obs[("Amazon CloudWatch · AWS X-Ray<br/>metrics · ingestion logs · traces")]:::obs
    end
    subgraph managed["AWS-managed boundary · Amazon Bedrock Managed Knowledge Base"]
        build["Build-time API · bedrock-agent<br/>CreateKnowledgeBase · CreateDataSource<br/>StartIngestionJob"]:::ai
        conn["Managed connectors<br/>crawl content and permissions"]:::ai
        parse["Managed parser and chunking<br/>text · images · audio · video"]:::ai
        embed["Embedding<br/>service-managed model or<br/>your 1,024-dimension float32 model"]:::ai
        store[("Managed storage<br/>embeddings · text · metadata · raw files · ACLs")]:::data
        runtime["Runtime API · bedrock-agent-runtime<br/>Retrieve · AgenticRetrieveStream<br/>GetDocumentContent"]:::ai
        rank["Hybrid search and reranker<br/>ACL filter from userContext"]:::ai
    end

    deploy -- "1. Create knowledge base and data source · HTTPS · SigV4" --> build
    build == "2. Ingestion job · on demand or scheduled" ==> conn
    conn -- "3. sts:AssumeRole" --> role
    conn -- "4. ListBucket · GetObject · service role" --> bucket
    conn -- "5. GetSecretValue · service role" --> secret
    conn -- "6. Crawl · HTTPS" --> src
    conn -- "7. Documents and permissions" --> parse
    parse -- "8. Chunks" --> embed
    embed -- "9. Vectors, text and ACLs" --> store
    key -- "10. Encrypt and decrypt through the grant" --> store
    app -- "11. Retrieve · TLS · SigV4" --> vpce
    vpce -- "12. AWS PrivateLink" --> runtime
    runtime -- "13. Query and userContext" --> rank
    rank -- "14. Search" --> store
    rank -- "15. Real-time ACL check · HTTPS" --> src
    runtime -. "16. retrievalResults" .-> app
    runtime == "17. Metrics, logs and traces" ==> obs

    subgraph legend["Legend"]
        l1["Deployer or client"]:::client
        l2["Your compute"]:::compute
        l3["Amazon Bedrock · managed"]:::ai
        l4[("Data at rest")]:::data
        l5["Security control"]:::security
        l6[("Observability")]:::obs
        l7["Outside your account"]:::external
    end

    classDef client   fill:#E8F1FB,stroke:#1F6FEB,color:#0B1F33
    classDef compute  fill:#FDEBD0,stroke:#D97706,color:#3B2300
    classDef ai       fill:#E6F4EA,stroke:#1E8E3E,color:#0B2E13
    classDef data     fill:#EDE7F6,stroke:#6A1B9A,color:#2A0A3D
    classDef security fill:#FDECEA,stroke:#C62828,color:#3D0A0A
    classDef obs      fill:#FFF8E1,stroke:#B28704,color:#3D2E00
    classDef external fill:#F1F3F4,stroke:#5F6368,color:#202124,stroke-dasharray:4 3
```

**Legend** — solid arrow: request or write · dashed arrow: response · thick arrow: asynchronous
job or telemetry · cylinder: data at rest · nested boxes: trust and network boundaries (third
party, your account, your VPC, AWS-managed service).

**What this shows** — three trust zones. The SaaS sources and your account are yours to secure;
the managed boundary is reachable only through the two Amazon Bedrock endpoints. Every line that
crosses into your account is authorised by a role you wrote: the service role for ingestion
(3 to 5), the caller's role for queries (11).

### Component roles

| Component | Role in this architecture | Security control |
|:--|:--|:--|
| Deployment role | Creates the knowledge base and data sources | `iam:PassRole` limited by `iam:PassedToService` = `bedrock.amazonaws.com` |
| Knowledge base service role | Identity that Amazon Bedrock assumes to read your sources | Trust policy with `aws:SourceAccount` and `aws:SourceArn`; least-privilege S3 and secret access |
| Amazon S3 bucket | Document source; also holds metadata and ACL files | Bucket policy; `aws:ResourceAccount` condition on the role; SSE |
| AWS Secrets Manager | Credentials for SaaS connectors | `secretsmanager:GetSecretValue` on named secrets only |
| AWS KMS customer managed key | Optional key for transient and stored data | Key policy for the creating identity via `bedrock.<region>.amazonaws.com`; grant retired on deletion |
| Managed connectors | Crawl content, and permissions when ACLs are enabled | Deletion protection threshold; sync schedule |
| Managed parser and chunking | Turn files, including media, into chunks | Media extraction enabled per data source |
| Embedding | Service-managed model, or your Bedrock model | Bring-your-own must be 1,024-dimension float32; type is immutable |
| Managed storage | Embeddings, text, metadata, raw files and ACLs | Encrypted; no direct customer access |
| Runtime API | `Retrieve`, `AgenticRetrieveStream`, `GetDocumentContent` | IAM on the knowledge base ARN; resource policy for other accounts |
| Hybrid search and reranker | Keyword plus semantic search, reranking, ACL filter | `userContext.userId`; fails closed; deny overrides allow |
| Interface VPC endpoints | Private path to both endpoints | Endpoint policy; security groups |
| Amazon CloudWatch and AWS X-Ray | Metrics, ingestion logs, `Retrieve` traces | `cloudwatch:PutMetricData` scoped to `AWS/Bedrock/KnowledgeBases` |

### Connections

| # | From → To | Protocol / operation | Direction of data | Auth |
|--:|:--|:--|:--|:--|
| 1 | Deployment role → Build-time API | HTTPS · `CreateKnowledgeBase`, `CreateDataSource` | Configuration in | SigV4, IAM |
| 2 | Build-time API → Managed connectors | `StartIngestionJob` or sync schedule | Job trigger | Service-internal |
| 3 | Managed connectors → Service role | `sts:AssumeRole` | Credentials out | Role trust policy |
| 4 | Managed connectors → Amazon S3 | `s3:ListBucket`, `s3:GetObject` | Documents into the service | Service role |
| 5 | Managed connectors → Secrets Manager | `secretsmanager:GetSecretValue` | Credentials into the service | Service role |
| 6 | Managed connectors → SaaS source | HTTPS | Documents and permissions into the service | Stored credentials |
| 7–9 | Connectors → Parser → Embedding → Storage | Service-internal | Chunks, vectors, ACLs | Service-internal |
| 10 | AWS KMS key → Managed storage | KMS grant | Data keys | Grant to Amazon Bedrock |
| 11–12 | Application → VPC endpoint → Runtime API | HTTPS over AWS PrivateLink · `Retrieve` | Query in | SigV4, IAM, endpoint policy |
| 13–14 | Runtime API → Search → Storage | Service-internal | Query, candidates | `userContext` ACL filter |
| 15 | Search → SaaS source | HTTPS | Access check | Stored credentials |
| 16 | Runtime API → Application | HTTPS response | Passages out | — |
| 17 | Runtime API → CloudWatch, X-Ray | Metrics, vended logs, traces | Telemetry out | Service role or caller identity |

## C. Sequence view

```mermaid
---
title: 08-C · Managed Knowledge Base (ingestion sync, then Retrieve)
---
sequenceDiagram
    autonumber
    participant Op as Operator or sync schedule
    participant BA as Amazon Bedrock build-time API (bedrock-agent)
    participant ING as Managed ingestion pipeline
    participant S3 as Amazon S3 data source
    participant ST as Managed storage
    participant App as Your application
    participant RT as Amazon Bedrock runtime API (bedrock-agent-runtime)
    Op->>BA: StartIngestionJob for a knowledgeBaseId and dataSourceId
    Note over Op,BA: TLS and SigV4 · IAM permission to start ingestion jobs
    BA-->>Op: ingestionJobId
    BA-)ING: Start incremental sync
    ING->>S3: ListBucket and GetObject
    Note over ING,S3: Knowledge base service role, assumed by bedrock.amazonaws.com
    S3-->>ING: Objects added, modified or deleted since the last sync
    ING->>ING: Parse, chunk and embed the changed documents
    alt Deletions exceed the deletion protection threshold
        ING->>ST: Index additions and updates, skip the delete phase
    else Deletions within the threshold
        ING->>ST: Index additions and updates, remove deleted documents
    end
    Note over ING,ST: Encrypted with the service default key or your KMS key
    Op->>BA: GetIngestionJob
    BA-->>Op: status COMPLETE with statistics
    App->>RT: Retrieve with retrievalQuery, managedSearchConfiguration and userContext
    Note over App,RT: TLS and SigV4 · IAM permission to retrieve from this knowledge base
    RT->>ST: Hybrid search with ACL pre-filter
    ST-->>RT: Candidate chunks
    RT->>RT: Rerank and apply real-time ACL verification where supported
    RT-->>App: retrievalResults with content, location, metadata and score
```

**Steps 1 to 11 — ingestion.** A sync starts on demand or on the data source's schedule. It is
incremental: only objects added, modified or deleted since the last sync are processed. The delete
phase is skipped when it would remove more than the deletion protection threshold. The job ends
with status `COMPLETE` and per-document statistics.

**Steps 12 to 16 — query.** `Retrieve` runs hybrid search, filters by the ingested ACLs for the
user in `userContext`, reranks and returns passages.

**Failure paths**

- The service role cannot read the bucket or the secret: the affected documents fail in the
  ingestion job; inspect the job statistics and the ingestion logs.
- A document in an ACL-enabled Amazon S3 source has no ACL entry: it is not ingested.
- `Retrieve` without `userContext`: ACL-enabled data sources return zero results.
- Real-time ACL verification fails or times out: the affected documents are withheld (fail closed).
- More than the per-knowledge-base request rate: HTTP 429 `ThrottlingException`.

## Variations

| Variation | What changes |
|:--|:--|
| Custom data source | No connector crawl and no sync: documents are pushed with `IngestKnowledgeBaseDocuments`. Edges 4 to 6 are replaced by your own ingestion code |
| Amazon S3 only | No Secrets Manager secret, no SaaS trust zone, no real-time ACL check (edge 15); ACLs come from files you provide |
| Bring-your-own embedding model | The embedding box invokes a Bedrock model in your account through the service role; the managed reranker is not available |
| Multimodal embedding model | An extra Amazon S3 multimodal storage bucket in your account, readable and writable by the service role |
| No customer managed key | The KMS node disappears; the service default key encrypts the data |
| Sync schedule | Edge 2 is triggered daily, weekly or monthly by the service instead of by `StartIngestionJob` |
| No VPC endpoints | Edges 11 and 12 become one HTTPS call to the public Regional endpoint |
| Agent access through AgentCore Gateway | The caller is a gateway with an IAM role; `Retrieve` and `AgenticRetrieveStream` are exposed as MCP tools |
| Cross-account consumer | A resource policy on the knowledge base allows `bedrock:Retrieve` and `bedrock:GetDocumentContent` for a role in another account |
| Agentic retrieval | The runtime runs a model-driven loop over the same storage — see [diagram set 9](09-agentic-retrieval.md) |
| AWS GovCloud (US-West) | Amazon S3 and Custom connectors only; no ACL filter; your own embedding model is required; no agentic retrieval; no Gateway target |

## Practical example

- [Managed Knowledge Base](../../01-amazon-bedrock/knowledge-bases/02-managed-knowledge-base.md),
  section 13 — validated Terraform for the service role, the knowledge base and an Amazon S3 data
  source, plus a `Retrieve` and `GetDocumentContent` call.
- [Project C: enterprise RAG with Knowledge Bases](../../05-practical-projects/project-03-enterprise-rag/README.md)
  — the full project built on this architecture.
- [Pattern: enterprise RAG](../../03-architecture-patterns/enterprise-rag/README.md) — where this
  component sits in a complete design.

## References

- [Build a managed knowledge base](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-build-managed.html) — what AWS manages; the comparison with customer-managed.
- [Create a managed knowledge base](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-managed-create.html) — embedding options, connectors, API shapes.
- [Connect a data source](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-managed-connect-ds.html) — connector configuration, deletion protection, media extraction, sync schedule.
- [Sync a data source](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-managed-sync.html) — incremental sync, job status, schedules.
- [Amazon S3 connector](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-managed-ds-s3.html) and [Custom](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-managed-ds-custom.html) — the two connectors drawn in the variations.
- [Access Control Lists awareness enablement](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-managed-acl.html) and [ACL-aware retrieval](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-test-retrieve-acl.html) — the two filter stages and fail-closed behaviour.
- [Create a service role for managed knowledge bases](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-managed-permissions.html) — trust policy and permissions on edges 3 to 5.
- [Encryption of knowledge base resources](https://docs.aws.amazon.com/bedrock/latest/userguide/encryption-kb.html) — the KMS grant on edge 10.
- [Resource policies for managed knowledge bases](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-managed-cross-account.html) — the cross-account variation.
- [Observability for managed knowledge bases](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-managed-observability.html) — metrics, logs and traces on edge 17.
- [Query a knowledge base and retrieve data](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-test-retrieve.html) and [Retrieve API reference](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_agent-runtime_Retrieve.html) — hybrid search, reranking, request and response fields.
- [Connect to your knowledge base through AgentCore Gateway](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-gateway-target.html) — the Gateway variation.
- [Interface VPC endpoints for Amazon Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/vpc-interface-endpoints.html) — endpoint service names on edges 11 and 12.
- [Supported AWS Regions](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-managed-regions.html) and [Service quotas](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-managed-quotas.html) — the GovCloud variation and the request rate.
