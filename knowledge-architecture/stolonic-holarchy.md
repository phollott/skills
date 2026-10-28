# Stolonic Holarchy

## A useful term: “stolonic holarchy”

You could call the resulting architecture a **stolonic holarchy**:

> A system of bounded, self-governing holons that can emit policy-bearing lateral offshoots. Those offshoots may take root in other contexts, accumulate distinct relationships and meaning, and remain linked—or eventually detach—from their origin.

It retains what is powerful about HGA:

- bounded context;
- policy boundaries;
- controlled projections;
- provenance;
- local state and validation;

while adding what a strict holarchy can suppress:

- lateral creativity;
- multiple belonging;
- remix;
- polycentric authorship;
- noncanonical interpretation;
- unexpected lines of development.

The arboreal structure can govern **what is authoritative and protected**. The stolonic/rhizomatic structure can model **how culture, ideas, and story matter actually travel, mutate, and root elsewhere**.

## Notes

That is a productive counterpoint—but I would frame it less as **holon versus rhizome** than as a tension between two architectural modes:

- **Holonic / arboreal mode:** local coherence, bounded identity, containment, responsibility, and controlled interfaces.
- **Rhizomatic / stolonic mode:** lateral connection, proliferation, reuse, unexpected cross-linkage, and the capacity to break away or re-root elsewhere.

HGA is structurally sympathetic to a holarchy: a holon is a bounded whole that is also part of a larger whole, with nesting as an important compositional relation. However, the current HGA materials also explicitly recognize **adjacency**—lateral connections among holons that do not imply containment. So HGA is not literally a strict tree; but its conceptual center of gravity is still closure, boundary mediation, inheritance, and coherence. ([github.com](https://github.com/w3c-cg/holon/blob/main/HCG_Proposed_Charter.md?utm_source=openai))

Deleuze and Guattari’s rhizome is a sharper challenge. They oppose the tree/root model’s genealogy and centralized organization with connection, heterogeneity, multiplicity, rupture, and maps with multiple entrances and exits. A rhizome has no privileged root or final endpoint; it grows “in the middle,” connecting heterogeneous things and changing its nature as it acquires new dimensions. ([web.english.upenn.edu](https://web.english.upenn.edu/~cavitch/pdf-library/Deleuze_and_Guattari_A_Thousand_Plateaus.pdf?utm_source=openai)) In your lore-card model, that means a card should not be understood only as *a child of a world*, *a member of a chapter*, or *an owned subgraph*. It can also be an **encounter point**: a “brass key” card might connect sideways to a mystery mechanic, an author’s private family-history thread, another creator’s setting, a game inventory system, a fan interpretation, and a separate story’s adaptation. Those links are not necessarily subordinate to one canonical parent.

## Why “stolon” may be the more useful design metaphor

A stolon is a horizontal stem that can root and produce a new shoot/plant at a node. ([blogs.ifas.ufl.edu](https://blogs.ifas.ufl.edu/hillsboroughco/2026/08/27/a-gardeners-guide-to-plant-propagation-part-i-the-anatomy-of-propagation/?utm_source=openai)) That makes it a particularly good model for **controlled lateral propagation**:

```text
Original lore holon
    ── stolon / licensed projection ──> recipient’s local lore card
                                              └─ may connect to new local material
                                              └─ may become an independent branch
```

This differs from both simple copying and hierarchical delegation.

- It is not a raw clone: it carries provenance, permissions, and a source relationship.
- It is not merely a child: the receiving world can develop independently.
- It is not necessarily a fork: it may remain linked to the originating lore while acquiring distinct local meaning.
- It can be severed: at some point, the derivative may become autonomous.

For your phone-bump backstory app, this is almost exact. A creator exposes a deliberately limited projection of a lore card—say, “The Observatory exists; it contains a sealed archive”—which takes root in another person’s story graph. The recipient can attach their own character, scene, or interpretation without receiving the creator’s hidden solution, internal notes, or protected IP.

## The counterpoint to holonic closure

A purely holonic design risks turning every meaningful relation into one of:

```text
contains
isPartOf
inheritsFrom
crossesBoundaryOf
```

That is excellent for policy, privacy, validation, authority, versioning, and task-sized context. But it can overstate canonical order in domains whose value arises from association, remix, interpretation, and emergence.

For narrative and collaborative lore, the more important relations may be:

```text
echoes
remixes
alludesTo
contradicts
reframes
borrowsUnderLicense
isInspiredBy
forksFrom
becomesRelevantTo
sharesMotifWith
```

These are not failures of containment. They are creative relations that often cut across containment.

A story world may have an official canon hierarchy, but fan practice, writers’ rooms, role-playing play, folklore, collaborative games, and personal note-taking often behave rhizomatically. The same piece of lore is simultaneously:

```text
a canonical object,
a clue,
a symbol,
a reusable prompt,
a private memory,
a licensed shared asset,
and a line into another world.
```

## A combined model: holons as nodes; stolons as propagation relations

I would not replace HGA. I would add a second relation family.

```text
Holon relations:
  contains
  partOf
  exposesProjection
  governs
  validates
  delegatesTo

Stolon relations:
  propagatesTo
  derivesFrom
  reusesProjectionOf
  carriesLicenseFrom
  locallyRecontextualizes
  mayDetachFrom
```

The key rule would be:

> **A holon governs its own boundary; a stolon carries a selected projection across boundaries and may root it in a new context.**

That gives you both capabilities:

| Need | Holonic mechanism | Stolonic/rhizomatic mechanism |
|---|---|---|
| Protect unrevealed lore | Boundary and restricted projection | Share only an allowed offshoot |
| Attribute source material | Provenance within a holon | Lineage from source card to derivative |
| Support remix | Controlled derivative-use policy | Lateral recontextualization |
| Preserve canon | Authority and canonical projection | Mark non-canonical derivatives explicitly |
| Allow surprise connections | Adjacent holons | New, unanticipated lateral links |
| Handle a split/fork | Version / branch relationship | Rooted offshoot that can later detach |

## Example: the Brass Key

```text
Private source holon:
  Brass Key

Private knowledge:
  Created by Mara’s mother.
  Opens the archive.
  Proves Ilyan covered up a death.

Public projection:
  A tarnished key associated with the observatory.
  Its exact purpose is unknown.
```

A stolonic transfer could be:

```text
Recipient World B receives:
  “Tarnished brass key associated with an abandoned observatory.”

Permissions:
  May use as a mysterious artifact.
  May add local history.
  Must attribute source.
  May not claim access to origin or secret function.
  May not redistribute the source’s private projection.
```

The recipient creates:

```text
World B’s Ash Key
  derivesFrom: source public projection
  local meaning: opens a subterranean library
  status: licensed derivative, non-canonical to source world
```

That is neither a simple containment hierarchy nor an uncontrolled flat graph. It is **governed rhizomatic growth**.

