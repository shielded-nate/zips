::

  ZIP: Unassigned {numbers are assigned by ZIP editors}
  Title: RSM-SL-v1: Crosslink Ledger State and Ledger Mutations
  Owners: Nate Wilcox <nate@shieldedlabs.com>
  Credits: Andrew Reece <andrew@shieldedlabs.com>
           Mark Hendersen <mark@shieldedlabs.net>
           Daira-Emma Hopwood
           Jack Grigg
           Kris Nuttycombe
  Status: Draft
  Category: Consensus
  Created: 2026-06-03
  License: MIT
  Discussions-To: TBD (no specific discussion thread yet)


Terminology
===========

The key words "MUST", "MUST NOT", "SHOULD", "SHOULD NOT", and "MAY" in this
text are to be interpreted as described in BCP 14 [#BCP14]_ when, and only
when, they appear in all capitals.

The terms "Mainnet" and "Testnet" in this document are to be interpreted as
defined in the Zcash protocol specification [#protocol-networks]_.

The terms below are to be interpreted as follows:

RSM-SL-v1
  The Shielded Labs v1 instantiation of the roster state module referenced by
  the Crosslink Overview ZIP [#zip-crosslink-overview]_.

Ledger state
  The full state computable from a given history implied by a PoW block hash,
  provided all of that history is objectively verifiable as consensus
  compatible. This ZIP shortens this, unambiguously to "ledger" after introducing
  the concept. Typically we focus only on the subset of computable state required
  for objectively verifying consensus (although in other contexts ledger state
  may include non-consensus inputs, such as shielded protocol ciphertexts which
  provide useful coordination between wallets).

Objective Verification
  The process of verifying a property _only_ using a given PoW block hash
  and all implied history. This "meta-property" may be applied to various
  properties of interest, though without qualification, the implied property is
  "complete consensus validity of the full ledger state". An example of a specific
  subproperty common to both Mainnet Zcash and Crosslink is objectively verifiable
  Difficulty-Adjustment Algorithm constraints.

Bond
  A ledger component consisting of an amount of bonded ZEC, a delegated finalizer,
  and a unique verifier for user wallets to authorize withdrawals or
  re-delegation.

Bond withdrawal
  Ledger state tracking a pending withdrawal of a bond, consisting of an amount
  of bonded ZEC, and a unique verifier for user wallets to complete a withdrawal
  into the Orchard pool.

Candidate Roster
  A ledger component mapping from Finalizer identifiers to voting weights,
  computed by summing all effective bonded amounts delegated to that
  Finalizer.

Active Roster
  The top ``ACTIVE_ROSTER_SLOTS`` entries of the Candidate Roster. This is
  the crucial intersection of consensus state and (potentially ephemeral) BFT
  subprotocol state which enables BFT to produce finality certificates and ledger
  consensus rules to safely rely on those certificates.

BFT Finality Certificate
  An attestation of the finality of a PoW block. This is often shortened to
  "finality certificate" unambiguously. The ledger consensus rules rely on
  finality certificates to provide the Crosslink Finality security property,
  which is objectively verifiable.

Crosslink Finality
  Crosslink Finality is a term capturing the five specific characteristics of
  finality which Crosslink aspires to provide. [FIXME: see the overview ZIP, or
  should we be consolidating these terms in a single ZIP?] Because this bundle
  of characteristics is specific to this project, as far as we are aware, we
  disambiguate with the "Crosslink" prefix. An example of how this is important
  is that stock BFT finality is not objectively verifiable, depending on specifics
  about particular protocol designs, whereas Crosslink ensures Crosslink Finality
  *is* objectively verifiable.

Most-Recent Final Ancestor
  The Most-Recent Final Ancestor is the most recent ancestor of a given PoW block
  which has objectively verifiable finality. This is often shortened to "final
  ancestor", and this is relatively safe and unambiguous, given that a more recent
  final state supercedes any previous known final state in terms of verifying
  consensus.

Final Ledger State
  The Final Ledger State given any PoW block is all of the Ledger State associated
  with the Most-Recent Final Ancestor of that PoW block. This definition simply
  combines the two objectively verifiable properties of the tip block's final
  ancestor and that ancestor's (recursively) objectively verifiable ledger state.

  This allows a conceptual and potential implementation simplification: the
  ledger state can be a single unified data structure for a given block, without
  a need or distinction to compute separate "pending versus final" state for that
  block. Instead there is only one kind of state computed and finality is reduced
  to only a matter of objectively verifiable historical position.

  This is also a useful constraint for safety analysis: no ledger consensus rule can
  have the form "the state if X if this block is pending, otherwise it is Y if it is
  final", thereby ensuring we can exclude swathes of complexity in consensus logic.

  FIXME: Is there a term for this kind of simplifying constraint that enables
  better static safety reasoning?

Anti-Terminology
----------------

Sometimes we notice terms or phrases take hold which we believe cause more confusion
than they are worth. This section lists relevant anti-terms and why we advocate
against using them in the context of Crosslink.

Validator
  This term is frequently used in PoS contexts, but we find it hazardous for
  Zcash or Crosslink for both normative and descriptive reasons.

  Normatively, Zcash aims to enable individuals to cooperate by relying on
  network-enforced consensus rules without any external authority, so the primary
  focus for protocol designers and developers building on the protocol with this
  ethos should be ensuring _individuals_ can _directly / locally verify_ a given
  history follows all ledger consensus rules without relying on the judgement of
  an external authority. By contrast "validator" may carry the connotation of an
  external authority vouching, attesting to, or designating a history "valid".

  Descriptively, for Crosslink itself, the active participants in BFT decisions are _only_ agreeing on the BFT finality status of 

  Consider this dictionary definition of the verb `validate`:

      *validate* transitive verb::

        1 a : to make legally valid : ratify
          b : to grant official sanction to by marking
          c : to confirm the validity of (an election)
            : to declare (a person) elected
        2 a : to support or corroborate on a sound or authoritative basis
          b : to recognize, establish, or illustrate the worthiness or legitimacy of

      -- Merriam-Webster: https://www.merriam-webster.com/dictionary/validator


   product and definitions with "legal" or "official"


Abstract
========

This ZIP specifies the subset of the Shielded Labs Crosslink v1 (SL Crosslink) design which modifies the Zcash *ledger state*. SL Crosslink is specified across several related ZIPs all of which assume the others as a whole. See `SL Crosslink Overview ZIP`_ for the overall design and relationships between these component ZIPs.

The *ledger state* is the heart of Zcash, where we can think of the consensus protocol, the network, wallets, and the whole ecosystem of products and services that people use to interact with Zcash as all about how to safely learn about or initiate changes to this ledger state.

We conceptualize the ledger state abstractly as a working memory data structure which is computable given _only_ a PoW block hash and its referenced history, with the assumption that this complete history is available as input to an abstract `ledger state function`.

FIXME: users concern also includes concensus agreement, not just valid state.

The primary concern of users is how their ZEC is tracked safely in this state, that they have the ability to spend it to recipients (safely and privately), and that the top-line rules that govern ZEC (such as the issuance schedule and cap or infeasibility of counterfeiting) are upheld. The ledger state encompasses these primary concerns.

The `ledger state function` computes 


Additionally, the ledger state consists of "all the other stuff" necessary to ensure these primary user concerns are taken care of, especially including:

- cryptographic data to protect against theft, to protect privacy, and to ensure fundamental ZEC scarcity,
- issuance rules

what all users care about, and it's maintenance and distribution is the whole purpose of the Zcash network and consensus protocol. The primary simple summary of this state is to track how balances of ZEC are held, plus 

- the balances of ZEC held,
- the rules for how ZEC is issued and distributed,
- and the transaction

 counterfeiting, and unnecessary exposure of private details, and the 

This ZIP specifies the Crosslink ledger state, ZEC accounting, and transaction changes required by Shielded Labs Crosslink v1. This ZIP 

, and by implication the transaction changes and overall ledger state consensus semantics. Ledger-state consensus

It defines the idealized point-in-time ledger state extension, and the ledger
mutation rules that update this state, including issuance distribution and
roster mutations.

The specification is layered:

* abstract Proof-of-Stake actions over ledger state, and
* concrete consensus extensions to Zcash transaction fields and semantics.


Motivation
==========

The Crosslink Overview ZIP defines RSM-SL-v1 conceptually but leaves the
consensus state and mutation details to a companion specification. Nodes need a
single, deterministic definition of:

* how Finalizer voting weights are derived from on-chain bonds,
* how the active BFT roster is selected, and
* how roster-related state evolves as blocks are applied and reverted.

Without this ZIP, implementations may diverge on ledger state interpretation,
producing incompatible active rosters and finality inputs.


Requirements
============

This ZIP MUST specify the following:

* An idealized ledger state extension over the existing Zcash ledger state,
  including bonds, Finalizer identifiers, and cryptographic material needed for
  self-authenticating roster membership.
* Candidate Roster construction by summing currently effective bonds per
  Finalizer, and Active Finalizer set selection as the top ``K = 100`` by
  voting weight.
* Dual-state interpretation in which ledger processing distinguishes finalized
  state from tip state, with each tip having an objectively verifiable
  most-recent-final ancestor.
* Ledger mutation rules for issuance distribution and roster mutations.
* A two-layer mutation definition:

  1. abstract PoS actions, and
  2. concrete Zcash transaction-field and transaction-semantic extensions.


Non-requirements
================

The following are out of scope for this ZIP:

* Pre-existing Zcash ledger state, except where it is extended or requires new
  considerations due to Crosslink.
* The Crosslink mechanism itself (including chain selection and finality-status
  verification), specified in CCC-SL [#zip-ccc-sl]_.
* Internal BFT protocol design, except that the Active Finalizer set is an
  input provided by this ZIP.
* Networking behavior outside transaction format and transaction semantics.
* Topics designated as separate ZIPs in the Crosslink overview
  [#zip-crosslink-overview]_.


Specification
=============

Idealized Ledger State Extension
--------------------------------

Let ``S_zec`` denote the existing Zcash ledger state. This ZIP defines an
extended idealized state ``S_xl`` that behaves as:

* ``S_xl = (S_zec, S_roster, S_finality_views, S_issuance)``.
* ``S_roster`` includes at minimum:

  * bond records keyed by bond identifier,
  * Finalizer identity records,
  * cryptographic verification keys and status metadata,
  * deterministic activation/deactivation metadata needed for roster
    computation.

* ``S_finality_views`` tracks finalized and tip-relative views so that, for each
  accepted tip, the corresponding most-recent-final ancestor is objectively
  derivable from block data and finalized commitments.
* ``S_issuance`` tracks distribution state required to apply issuance rules that
  involve Finalizers.

Consensus behavior MUST be equivalent to transitions over ``S_xl`` even when an
implementation does not materialize ``S_xl`` as one in-memory object.

Candidate Roster and Active Finalizers
--------------------------------------

For each state ``S_xl`` at a given chain point:

* Candidate voting weight for Finalizer ``f`` is the sum of all currently
  effective bond amounts targeting ``f``.
* Candidate Roster computation MUST be deterministic for every honest node given
  the same chain history.
* The Active Finalizer set is the top ``K = 100`` Finalizers by candidate voting
  weight.
* Tie-breaking for equal weights MUST be deterministic and based only on
  consensus-visible data.
* The active roster output MUST be suitable as an input to CFP-SL voting-weight
  selection.

Finalized and Tip State Relationship
------------------------------------

Ledger processing MUST expose both:

* a finalized state view anchored at finalized history, and
* a tip state view for each accepted PoW tip.

For every accepted tip, nodes MUST be able to derive an objectively verifiable
most-recent-final ancestor from consensus data. Reorganizations MUST preserve
this invariant and recompute dependent tip state deterministically.

Ledger Mutations: Abstract Action Layer
---------------------------------------

This ZIP defines abstract actions that mutate ``S_xl``:

* ``BondCreate``: create a bond linking stake to a Finalizer identifier.
* ``BondAdjust``: increase or decrease an existing bond according to consensus
  constraints.
* ``BondDeactivate``: transition stake out of active weighting, including
  unbonding behavior.
* ``FinalizerRegister`` and ``FinalizerUpdate``: manage Finalizer identity and
  associated cryptographic keys.
* ``FinalizerDeactivate``: remove a Finalizer from future roster eligibility.
* ``Slash``: apply deterministic penalties for provable misbehavior.
* ``DistributeIssuance``: apply issuance distribution updates affecting miner
  and Finalizer-related allocation state.

Each action MUST define preconditions, state transition effects, and reversion
behavior under chain rollback.

Ledger Mutations: Concrete Zcash Transaction Semantics
------------------------------------------------------

Consensus transaction rules are extended so that specific transaction patterns
encode the abstract actions above. This layer MUST define:

* the concrete transaction fields and encodings used for roster-related actions,
* validity checks for signatures, authorization, and amount constraints,
* ordering and interaction rules when multiple roster actions appear in one
  block,
* rejection behavior for malformed, unauthorized, or semantically conflicting
  actions.

Applying a valid block MUST induce exactly the same abstract action sequence on
``S_xl`` at all honest nodes.

Issuance Distribution and Roster Interaction
--------------------------------------------

Issuance distribution rules covered by this ZIP MUST specify:

* which issuance components are affected by roster/finalizer state,
* when issuance state updates occur relative to other per-block mutations, and
* deterministic accounting behavior under normal progression and reorgs.

Detailed policy values (for example, exact allocation percentages) MAY be set by
separate process or funding ZIPs, but this ZIP defines the consensus state
transition hooks that enforce whichever policy is activated.


Protocol Constant Parameters
----------------------------

These parameters are fixed constants used in Crosslink ledger consensus verification:

- ``ACTIVE_ROSTER_SLOTS = 100``, the maximum number of finalizers which participate
  in producing a BFT Finality Certificate.

Rationale
=========

Separating this specification from CCC-SL keeps concerns modular:

* CCC-SL specifies the hybrid-consensus construction and finality properties.
* This ZIP specifies the ledger-state machine that supplies active roster input
  and applies roster-related mutations inside Zcash consensus processing.

This split keeps each ZIP auditable while preserving deterministic integration.


Deployment
==========

This ZIP is intended to activate through the Zcash network-upgrade mechanism
[#zip-0200]_ alongside the other required Crosslink ZIPs.


Reference Implementation
========================

A prototype implementation is under development in the Shielded Labs
``zebra-crosslink`` and ``crosslink_monolith`` repositories, referenced from
ZIP [#zip-crosslink-overview]_.


References
==========

.. [#BCP14] `Information on BCP 14 — "RFC 2119: Key words for use in RFCs to Indicate Requirement Levels" and "RFC 8174: Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words" <https://www.rfc-editor.org/info/bcp14>`_
.. [#protocol] `Zcash Protocol Specification, Version 2022.3.8 or later <protocol/protocol.pdf>`_
.. [#protocol-networks] `Zcash Protocol Specification, Version 2022.3.8. Section 3.12: Mainnet and Testnet <protocol/protocol.pdf#networks>`_
.. [#zip-0200] `ZIP 200: Network Upgrade Mechanism <zip-0200.rst>`_
.. [#zip-ccc-sl] `ZIP [Unassigned]: CCC-SL: Crosslink Consensus Construction from Shielded Labs <draft-shieldedlabs-crosslink-construction.rst>`_
.. [#zip-crosslink-overview] `ZIP [Unassigned]: Shielded Labs Crosslink v1: Protocol Overview and Architecture <draft-shieldedlabs-crosslink-overview.rst>`_
