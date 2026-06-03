::

  ZIP: Unassigned {numbers are assigned by ZIP editors}
  Title: RSM-SL-v1: Crosslink Ledger State from Shielded Labs
  Owners: Nate Wilcox <nate@shieldedlabs.com>
  Credits: Daira-Emma Hopwood
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
document are to be interpreted as described in BCP 14 [#BCP14]_ when, and only
when, they appear in all capitals.

The terms "Mainnet" and "Testnet" in this document are to be interpreted as
defined in the Zcash protocol specification [#protocol-networks]_.

The terms below are to be interpreted as follows:

RSM-SL-v1
  The roster state module specified by this ZIP. RSM-SL-v1 defines the ledger
  state transitions required for Crosslink staking and finalization rights.

Finalizer identity
  A consensus-visible identity key used to authorize participation in
  Crosslink finalization voting.

Bond
  A quantity of ZEC locked in consensus state under RSM-SL-v1 rules to secure
  finalization participation.

Finalizer roster
  The consensus state mapping from active Finalizer identities to their voting
  weights and related status required by the finalization protocol.

PoS action
  A transaction-level action defined by this ZIP that updates RSM-SL-v1 state,
  such as bonding, unbonding, activation, deactivation, reward claim, and
  delegated stake changes.


Abstract
========

This ZIP specifies the **ledger state changes** required for Shielded Labs
Crosslink v1 [#zip-crosslink-overview]_, including the transaction-level rules
and semantics needed to evolve that ledger state under consensus.

The scope includes bonds, Finalizer identities, the Finalizer roster, PoS
actions, and PoS rewards distribution.

This ZIP does **not** specify the Crosslink Mechanism itself, the BFT protocol,
or networking protocols; those are covered in companion ZIPs.


Motivation
==========

Crosslink requires consensus-tracked stake and roster state so that finalizer
rights, voting power, and accountability are objectively derived from the
ledger.

Without a dedicated ledger-state ZIP, critical protocol behavior would remain
underspecified or fragmented across implementation-specific logic:

* how stake enters and exits bonded state;
* how Finalizer identities are registered, updated, and removed;
* how the active Finalizer roster is derived and updated over time;
* how PoS-related transaction actions are represented and validated;
* how PoS rewards are allocated and distributed.

A single consensus ZIP for these rules enables interoperable implementations and
clear separation of concerns from Crosslink construction, BFT internals, and
network transport.


Requirements
============

The ledger-state design specified in this ZIP MUST:

* define deterministic consensus state for Finalizer identities, bonds, and
  active roster membership;
* specify transaction validity and state-transition semantics for PoS actions;
* specify deterministic reward accounting and reward distribution semantics;
* preserve objective verifiability from chain data;
* be deployable on both Mainnet and Testnet with network-specific parameters.


Non-requirements
================

This ZIP is explicitly not responsible for:

* specifying the Crosslink consensus construction (CCC-SL), which is covered by
  ZIP [#zip-crosslink-construction]_.
* specifying the internal BFT algorithm or message flow of the finalization
  protocol.
* specifying p2p networking or transport mechanisms for Crosslink finalization
  traffic.


Specification
=============

This first draft defines scope and high-level consensus responsibilities for
RSM-SL-v1. Normative transaction encodings, parameter values, and full
state-transition equations are to be added in subsequent revisions.

Ledger state objects
--------------------

Consensus implementations MUST track, at minimum, the following logical state:

* Finalizer identity records;
* bond records and bond lifecycle state;
* active Finalizer roster state used to derive voting weights;
* reward accounting state for PoS reward distribution.

PoS transaction semantics
-------------------------

Consensus transaction validation MUST define PoS actions that modify RSM-SL-v1
state. At minimum, this action set MUST cover:

* creation and update of Finalizer identities;
* bond creation and increase;
* unbond initiation and completion;
* state transitions affecting roster eligibility;
* reward claim and reward distribution effects.

Each PoS action MUST have deterministic preconditions, state transition effects,
and failure conditions, and MUST be validated consistently across
implementations.

Finalizer roster derivation
---------------------------

The active Finalizer roster MUST be a deterministic function of consensus ledger
state at a given chain tip. Roster updates caused by PoS actions MUST follow
consensus-defined timing and transition rules.

Reward distribution
-------------------

PoS rewards MUST be distributed according to consensus-defined accounting rules
and MUST be derivable from chain data. Reward attribution and claim semantics
MUST be deterministic and auditable.

Mainnet and Testnet applicability
---------------------------------

This ZIP applies to both Mainnet and Testnet. Any network-specific constants
MUST be explicitly enumerated in a future revision.

Open questions
--------------

* Final transaction encoding and versioning strategy for PoS actions.
* Precise activation/deactivation timing rules for roster membership.
* Slashing interaction points and evidence handling boundaries with CFP-SL.
* Reward cadence, rounding behavior, and edge-case handling.


Deployment
==========

Activation strategy, heights, and branch identifiers are out of scope for this
draft and are expected to be specified by a dedicated deployment ZIP.


References
==========

.. [#BCP14] `Information on BCP 14 — "RFC 2119: Key words for use in RFCs to Indicate Requirement Levels" and "RFC 8174: Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words" <https://www.rfc-editor.org/info/bcp14>`_
.. [#protocol-networks] `Zcash Protocol Specification. Section 3.12: Mainnet and Testnet <protocol/protocol.pdf#networks>`_
.. [#zip-crosslink-overview] `Draft: Shielded Labs Crosslink v1: Protocol Overview and Architecture <draft-shieldedlabs-crosslink-overview.rst>`_
.. [#zip-crosslink-construction] `Draft: CCC-SL: Crosslink Consensus Construction from Shielded Labs <draft-shieldedlabs-crosslink-construction.rst>`_
