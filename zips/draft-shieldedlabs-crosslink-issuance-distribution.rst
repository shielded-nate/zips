::

  ZIP: Unassigned {numbers are assigned by ZIP editors}
  Title: Crosslink Issuance Distribution
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

.. admonition:: TODO

   Fill out terms and link to overview ZIP as appropriate.

Requirements
============

Supply Integrity
----------------

The specification MUST ensure these `Supply Integrity Properties`:

1. Redistribution of ZEC cannot alter the supply.

   a. Any redistribution operation of ZEC (including transfers, issuance, unissuance, etc...) is considered to `consume` an explicit amount of ZEC and to instantly `produce` an equivalent amount of ZEC atomically from the perspective of consensus.

   b. The amounts consumed and produced must be representable in units of ``ZATOSHI`` with 64 bit unsigned integer precision.

   c. .. _decomposed-sum-form:

	   *Every* redistribution must be decomposable into the form $c_a + c_b = p_a + p_b$ where all four variables are representable as unsigned 64 bit integers where $+$ is integer addition modulo $2^64$, the sums are guaranteed not to overflow by explicitly documented preconditional assumptions, and equality is natural order comparison. A single redistribution rule may iteratively or inductively decompose into this elementary form.

   d. Where proportions or ratios require division, that must be calculated as $q = \lfloor \frac{n}{d} \rfloor$ where $n$ and $d$ are unsigned 64 bit integers and $d$ is guaranteed by explicit documented precondition to not be $0$. This calculation must precede a sum-based redistribution in the form of the preceding `decomposed-sum-form`_ which ensures that regardless of rounding error, all ZEC is preserved.


2. Issuance and unissuance must meet the redistribution requirements of 1 with these exceptional considerations:

   a. Terms on either side of the equality
   b. Every redistribution must be decomposable into this direct sum  where each variable may be represented as a 64bit unsigned integer.

Specification
=============

The specification is split into a `Conceptual Specification`_ which uses mathematical notation and describes verification rules at a high level with an intended audience of anyone interested in staking or finalization distribution rules, and a `Concrete Specification`_ using pseudocode aimed at implementors and code analysis.

Conceptual Specification
------------------------

This higher-level specification states the verification rules in a more "natural" way that might match verbal explanations given to users about the accounting rules of Proof of Stake in `SL Crosslink`. At the same time, it aims to be mathematically precise *except for* accounting for numerical calculation errors.

Notational Conventions
~~~~~~~~~~~~~~~~~~~~~~

.. admonition:: TODO

   Figure out where this section should live?

We use these conventions in mathematical notation:

- $\mathsf{BondId}$ represents the set of all possible `bond identifiers`. These are unique identifiers which can also be used to verify signatures bound to a uniquely associated signing secret. The notation $b \in \mathsf{BondId}$ indicates $b$ is one such identifier.
- $\mathsf{FinalizerId}$ represents the set of all possible `finalizer identifiers`. These are unique identifiers which can also be used to verify signatures bound to a uniquely associated signing secret. The notation $f \in \mathsf{FinalizerId}$ indicates $f$ is one such identifier.

The Consensus Infrastructure Budget
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Conceptually, in each block at height $h$, the `ZEC Issuance Policy` allocates `block subsidy`, which includes a `Consensus Infrastructure Budget (CIB)` of *up to and no more than* $S_h$ ZEC to be allocated by the `Zcash consensus protocol`. This is a conceptual reframing of the relationships between the `ZEC Issuance Policy` and CIB which is intended to be generic over issuance policies and consensus algorithms (so for example it applies to current and historical Mainnet Zcash) which serves to delineate the scope and interactions of `SL Crosslink` with the rest of the existing Zcash protocol.

In `Zcash NU6.1` and earlier, the CIB is allocated entirely to the `miner subsidy`. When the active `Zcash consensus protocol` is `SL Crosslink`, any `verifier` must ensure the CIB distribution follows these rules:

1. The budget is divided in half between the `PoW` and `PoS` subprotocols: $S_h = S^{PoW}_h + S^{PoS}_h$, where:

    - $S^{PoW}_h = 50\%\  S_h$
    - $S^{PoS}_h = 50\%\  S_h$

2. The `PoW` budget is distributed to the miner of the current block by the same mechanism as [#coinbase-transactions]_.
3. The budget for `PoS` is split between 90% `Bond Rewards`, $R_h$, and 10% `Finalizer Commissions`, $C_h$: $S^{PoS}_h = R_h + C_h$, where:

    - $R_h = 90\%\  S^{PoS}_h$
    - $C_h = 10\%\  S^{PoS}_h$

4. The `Bond Rewards`, $R_h$, are split proportionally among the bonds current at that height, as described below in `Bond Rewards`_.
5. Up to $C_h$ `Finalizer Commissions` are split among `Active Finalizers` as described below in `Finalizer Commissions`_.
6. Any undistributed ZEC left in the `Finalizer Commissions` or due to numerical rounding (see `Numerical Error`_) is considered to be not issued in this block, whose impact depends on the `ZEC Issuance Policy`. (In [zcash-nu6.1]_ such ZEC would remain unissued indefinitely, while with [#ZIP-0234]_ activation, the unissued ZEC may contribute to future issuance.)

Bond Rewards
~~~~~~~~~~~~

The `Bond Rewards` for a block, $R_h$, are distributed logically proportionally among all existing `bonds` at height $h$. A direct `Ledger State` and algorithm to fulfill this requirement is given as follows:

Naive Bond Rewards Distribution
'''''''''''''''''''''''''''''''

Let $b^i_h$ be a `running bond balance` in the `Ledger State` for height $h$ for a bond with identity $i \in \mathsf{BondId}$.

Let $B_h$ be the sum of `running bond balance` values at a given height: $B_h = \sum_{i} b^i_h$

When calculating the `Ledger State` for height $h$, follow these steps for each `running bond balance`, $b^i_h$:

1. Calculate the bond's block reward: $r^i_h = \frac{ b^i_{h - 1} }{ B_{h - 1} } R_h$
2. Increment the `running bond balance` by the reward: $b^i_h = b^i_{h-1} + r^i_h$

This is called "naive" because there is a significantly more efficient specification given in the `Concrete Specification`_ below.

Finalizer Commissions
~~~~~~~~~~~~~~~~~~~~~

At some height $h$, each bond $i$ `endorses` some finalizer $\operatorname{endorse}(i) = f$ and we define the `finalizer weight` at that height to be the sum of `running bond balances` for that finalizer:

.. math::

   W^f_h = \sum_{i} b^i_h \quad \text{where } \operatorname{endorsement}(i) = f

The `candidate finalizer roster` at height $h$ is the list of finalizers sorted by finalizer weight from greatest weight at index `0` to least weight. The `active finalizer roster` consists of the top `K` entries on the `candidate finalizer roster` with this weight-based sorting.

The `ledger state` for height $h$ includes an `accumulated finalizer commissions` counter for *every* finalizer on the roster, denominated in ``ZATOSHI``

.. admonition:: FIXME

   The ledger state must track both finalizers with any weight > 0 *and* finalizers with any `accumulated finalizer commisions` > 0!

.. admonition:: TODO

   Complete finalizer commission abstract specification.


Concrete Specification
----------------------

The `Conceptual Specification`_ is written using math notation and high-level rule statements to aid in understanding and describing the Proof of Stake rewards distribution, which can be of interest especially to a broad range of users who are staking or operating finalizers. In this section, we focus on specification better suited to software implementors and code reviewers. It's important that we demonstrate these specifications are equivalent to the conceptual specification, especially where we've introduced optimizations. Additionally, the conceptual specification glosses over numerical arithmetic error, which we treat explicitly in this section.

.. admonition:: TODO

   Fill out this section; use ``CODE_FRIENDLY_CONSTANTS`` and ``variable_names`` and pseudocode rather than math notation.

Numerical Error
---------------

In every arithmetic operation over ZEC values, consensus verification requires explicit handling of numeric error to achieve this strict requirement:


.. admonition:: TODO

   Fill out this section which specifies precisely how to handle numerical error



References
==========

.. [#BCP14] `Information on BCP 14 — "RFC 2119: Key words for use in RFCs to Indicate Requirement Levels" and "RFC 8174: Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words" <https://www.rfc-editor.org/info/bcp14>`_
.. [#zcash-nu6.1] `Zcash Protocol Specification, Version 2025.6.2 [NU6.1]. <protocol/protocol.pdf>`_
.. [#protocol-networks] `Zcash Protocol Specification, Version 2025.6.2 [NU6.1]. Section 3.12: Mainnet and Testnet <protocol/protocol.pdf#networks>`_
.. [#coinbase-transactions] `Zcash Protocol Specification, Version 2025.6.2 [NU6.1]. Section 3.11: Coinbase Transactions <protocol/protocol.pdf#coinbase_transactions>`_
.. [#zec-issuance-policy] `DRAFT ZIP: Shielded Labs Crosslink v1: Protocol Overview and Architecture <draft-shieldedlabs-crosslink-overview.rst>`_
.. [#zip-0234] `ZIP 234: Network Sustainability Mechanism: Issuance Smoothing <zip-0234.md>`_
