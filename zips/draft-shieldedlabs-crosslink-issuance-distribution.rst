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

Conceptual Specification
------------------------

Conceptually, in each block at height $h$, the `ZEC Issuance Policy` allocates `block subsidy`, which includes a `Consensus Infrastructure Budget (CIB)` of *up to and no more than* $S_h$ ZEC to be allocated by the `Zcash consensus protocol`. In `Zcash NU6.1` and earlier, the CIB is allocated entirely to the `miner subsidy`. When the active `Zcash consensus protocol` is `SL Crosslink`, any `verifier` must ensure the CIB distribution follows these rules:

1. The budget is divided in half between the `PoW` and `PoS` subprotocols: $S_h = S^{PoW}_h + S^{PoS}_h$, where:

    - $S^{PoW}_h = 50\%\  S_h$
    - $S^{PoS}_h = 50\%\  S_h$

2. The `PoW` budget is distributed to the miner of the current block by the same mechanism as [#coinbase-transactions]_.
3. The budget for `PoS` is split between 90% `Bond Rewards`, $R_h$, and 10% `Finalizer Commissions`, $C_h$: $S^{PoS}_h = R_h + C_h$, where:

    - $R_h = 90\%\  S^{PoS}_h$
    - $C_h = 10\%\  S^{PoS}_h$

4. The `Bond Rewards`, $R_h$, are split proportionally among the bonds current at that height, as described below in `Bond Rewards`_.
5. Up to $C_h$ `Finalizer Commissions` are split among `Active Finalizers` as described below in `Finalizer Commissions`_.
6. Any undistributed ZEC left in the `Finalizer Commissions` or due to numerical rounding (see `Numerical Error`_) is considered to be not issued in this block, whose impact depends on the `ZEC Issuance Policy`_. (In [zcash-nu-6.1]_ such ZEC would remain unissued indefinitely, while with `ZIP XXXX FIXME`_ the unissued ZEC may contribute to future issuance.)

Bond Rewards
~~~~~~~~~~~~

The `Bond Rewards` for a block, $R_h$, are distributed logically proportionally among all existing `bonds` at height $h$. A direct `Ledger State` and algorithm to fulfill this requirement is given as follows:

Naive Bond Rewards Distribution
'''''''''''''''''''''''''''''''

Let $b^{<i>}_h$ be a `running bond balance` in the `Ledger State` for height $h$ for a bond with identity $<i>$. The angle bracket notation, $<\cdot>$, emphasizes each bond's unique identity while the set of bonds may change over block heights (so a "bare index" $i$ may be hazardously misleading).

Let $B_h$ be the sum of `running bond balance` values at a given height: $B_h = \sum_{<i>} b^{<i>}_h$

When calculating the `Ledger State` for height $h$, follow these steps for each `running bond balance`, $b^{<i>}_h$:

1. Calculate the bond's block reward: $r^{<i>}_h = \frac{ b^{<i>}_{h - 1} }{ B_{h - 1} } R_h$
2. Increment the `running bond balance` by the reward: $b^{<i>}_h = b^{<i>}_{h-1} + r^{<i>}_h$

Numerical Error
---------------

In every arithmetic operation over ZEC values, consensus verification requires explicit handling of numeric error to achieve this strict requirement:


.. admonition:: TODO

   Fill out this section which specifies precisely how to handle numerical error



References
==========

.. [#BCP14] `Information on BCP 14 — "RFC 2119: Key words for use in RFCs to Indicate Requirement Levels" and "RFC 8174: Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words" <https://www.rfc-editor.org/info/bcp14>`_
.. [#protocol-networks] `Zcash Protocol Specification, Version 2025.6.2 [NU6.1]. Section 3.12: Mainnet and Testnet <protocol/protocol.pdf#networks>`_
.. [#coinbase-transactions] `Zcash Protocol Specification, Version 2025.6.2 [NU6.1]. Section 3.11: Coinbase Transactions <protocol/protocol.pdf#coinbase_transactions>`_
