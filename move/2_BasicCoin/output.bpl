
// ** Expanded prelude

// Copyright (c) The Diem Core Contributors
// Copyright (c) The Move Contributors
// SPDX-License-Identifier: Apache-2.0

// Basic theory for vectors using arrays. This version of vectors is not extensional.

type {:datatype} Vec _;

function {:constructor} Vec<T>(v: [int]T, l: int): Vec T;

function {:builtin "MapConst"} MapConstVec<T>(T): [int]T;
function DefaultVecElem<T>(): T;
function {:inline} DefaultVecMap<T>(): [int]T { MapConstVec(DefaultVecElem()) }

function {:inline} EmptyVec<T>(): Vec T {
    Vec(DefaultVecMap(), 0)
}

function {:inline} MakeVec1<T>(v: T): Vec T {
    Vec(DefaultVecMap()[0 := v], 1)
}

function {:inline} MakeVec2<T>(v1: T, v2: T): Vec T {
    Vec(DefaultVecMap()[0 := v1][1 := v2], 2)
}

function {:inline} MakeVec3<T>(v1: T, v2: T, v3: T): Vec T {
    Vec(DefaultVecMap()[0 := v1][1 := v2][2 := v3], 3)
}

function {:inline} MakeVec4<T>(v1: T, v2: T, v3: T, v4: T): Vec T {
    Vec(DefaultVecMap()[0 := v1][1 := v2][2 := v3][3 := v4], 4)
}

function {:inline} ExtendVec<T>(v: Vec T, elem: T): Vec T {
    (var l := l#Vec(v);
    Vec(v#Vec(v)[l := elem], l + 1))
}

function {:inline} ReadVec<T>(v: Vec T, i: int): T {
    v#Vec(v)[i]
}

function {:inline} LenVec<T>(v: Vec T): int {
    l#Vec(v)
}

function {:inline} IsEmptyVec<T>(v: Vec T): bool {
    l#Vec(v) == 0
}

function {:inline} RemoveVec<T>(v: Vec T): Vec T {
    (var l := l#Vec(v) - 1;
    Vec(v#Vec(v)[l := DefaultVecElem()], l))
}

function {:inline} RemoveAtVec<T>(v: Vec T, i: int): Vec T {
    (var l := l#Vec(v) - 1;
    Vec(
        (lambda j: int ::
           if j >= 0 && j < l then
               if j < i then v#Vec(v)[j] else v#Vec(v)[j+1]
           else DefaultVecElem()),
        l))
}

function {:inline} ConcatVec<T>(v1: Vec T, v2: Vec T): Vec T {
    (var l1, m1, l2, m2 := l#Vec(v1), v#Vec(v1), l#Vec(v2), v#Vec(v2);
    Vec(
        (lambda i: int ::
          if i >= 0 && i < l1 + l2 then
            if i < l1 then m1[i] else m2[i - l1]
          else DefaultVecElem()),
        l1 + l2))
}

function {:inline} ReverseVec<T>(v: Vec T): Vec T {
    (var l := l#Vec(v);
    Vec(
        (lambda i: int :: if 0 <= i && i < l then v#Vec(v)[l - i - 1] else DefaultVecElem()),
        l))
}

function {:inline} SliceVec<T>(v: Vec T, i: int, j: int): Vec T {
    (var m := v#Vec(v);
    Vec(
        (lambda k:int ::
          if 0 <= k && k < j - i then
            m[i + k]
          else
            DefaultVecElem()),
        (if j - i < 0 then 0 else j - i)))
}


function {:inline} UpdateVec<T>(v: Vec T, i: int, elem: T): Vec T {
    Vec(v#Vec(v)[i := elem], l#Vec(v))
}

function {:inline} SwapVec<T>(v: Vec T, i: int, j: int): Vec T {
    (var m := v#Vec(v);
    Vec(m[i := m[j]][j := m[i]], l#Vec(v)))
}

function {:inline} ContainsVec<T>(v: Vec T, e: T): bool {
    (var l := l#Vec(v);
    (exists i: int :: InRangeVec(v, i) && v#Vec(v)[i] == e))
}

function IndexOfVec<T>(v: Vec T, e: T): int;
axiom {:ctor "Vec"} (forall<T> v: Vec T, e: T :: {IndexOfVec(v, e)}
    (var i := IndexOfVec(v,e);
     if (!ContainsVec(v, e)) then i == -1
     else InRangeVec(v, i) && ReadVec(v, i) == e &&
        (forall j: int :: j >= 0 && j < i ==> ReadVec(v, j) != e)));

// This function should stay non-inlined as it guards many quantifiers
// over vectors. It appears important to have this uninterpreted for
// quantifier triggering.
function InRangeVec<T>(v: Vec T, i: int): bool {
    i >= 0 && i < LenVec(v)
}

// Copyright (c) The Diem Core Contributors
// Copyright (c) The Move Contributors
// SPDX-License-Identifier: Apache-2.0

// Boogie model for multisets, based on Boogie arrays. This theory assumes extensional equality for element types.

type {:datatype} Multiset _;
function {:constructor} Multiset<T>(v: [T]int, l: int): Multiset T;

function {:builtin "MapConst"} MapConstMultiset<T>(l: int): [T]int;

function {:inline} EmptyMultiset<T>(): Multiset T {
    Multiset(MapConstMultiset(0), 0)
}

function {:inline} LenMultiset<T>(s: Multiset T): int {
    l#Multiset(s)
}

function {:inline} ExtendMultiset<T>(s: Multiset T, v: T): Multiset T {
    (var len := l#Multiset(s);
    (var cnt := v#Multiset(s)[v];
    Multiset(v#Multiset(s)[v := (cnt + 1)], len + 1)))
}

// This function returns (s1 - s2). This function assumes that s2 is a subset of s1.
function {:inline} SubtractMultiset<T>(s1: Multiset T, s2: Multiset T): Multiset T {
    (var len1 := l#Multiset(s1);
    (var len2 := l#Multiset(s2);
    Multiset((lambda v:T :: v#Multiset(s1)[v]-v#Multiset(s2)[v]), len1-len2)))
}

function {:inline} IsEmptyMultiset<T>(s: Multiset T): bool {
    (l#Multiset(s) == 0) &&
    (forall v: T :: v#Multiset(s)[v] == 0)
}

function {:inline} IsSubsetMultiset<T>(s1: Multiset T, s2: Multiset T): bool {
    (l#Multiset(s1) <= l#Multiset(s2)) &&
    (forall v: T :: v#Multiset(s1)[v] <= v#Multiset(s2)[v])
}

function {:inline} ContainsMultiset<T>(s: Multiset T, v: T): bool {
    v#Multiset(s)[v] > 0
}

// Copyright (c) The Diem Core Contributors
// Copyright (c) The Move Contributors
// SPDX-License-Identifier: Apache-2.0

// Theory for tables.

type {:datatype} Table _ _;

// v is the SMT array holding the key-value assignment. e is an array which
// independently determines whether a key is valid or not. l is the length.
//
// Note that even though the program cannot reflect over existence of a key,
// we want the specification to be able to do this, so it can express
// verification conditions like "key has been inserted".
function {:constructor} Table<K, V>(v: [K]V, e: [K]bool, l: int): Table K V;

// Functions for default SMT arrays. For the table values, we don't care and
// use an uninterpreted function.
function DefaultTableArray<K, V>(): [K]V;
function DefaultTableKeyExistsArray<K>(): [K]bool;
axiom DefaultTableKeyExistsArray() == (lambda i: int :: false);

function {:inline} EmptyTable<K, V>(): Table K V {
    Table(DefaultTableArray(), DefaultTableKeyExistsArray(), 0)
}

function {:inline} GetTable<K,V>(t: Table K V, k: K): V {
    // Notice we do not check whether key is in the table. The result is undetermined if it is not.
    v#Table(t)[k]
}

function {:inline} LenTable<K,V>(t: Table K V): int {
    l#Table(t)
}


function {:inline} ContainsTable<K,V>(t: Table K V, k: K): bool {
    e#Table(t)[k]
}

function {:inline} UpdateTable<K,V>(t: Table K V, k: K, v: V): Table K V {
    Table(v#Table(t)[k := v], e#Table(t)[k := true], l#Table(t))
}

function {:inline} AddTable<K,V>(t: Table K V, k: K, v: V): Table K V {
    // This function has an undetermined result if the key is already in the table
    // (all specification functions have this "partial definiteness" behavior). Thus we can
    // just increment the length.
    Table(v#Table(t)[k := v], e#Table(t)[k := true], l#Table(t) + 1)
}

function {:inline} RemoveTable<K,V>(t: Table K V, k: K): Table K V {
    // Similar as above, we only need to consider the case where the key is in the table.
    Table(v#Table(t), e#Table(t)[k := false], l#Table(t) - 1)
}


// ============================================================================================
// Primitive Types

const $MAX_U8: int;
axiom $MAX_U8 == 255;
const $MAX_U64: int;
axiom $MAX_U64 == 18446744073709551615;
const $MAX_U128: int;
axiom $MAX_U128 == 340282366920938463463374607431768211455;

type {:datatype} $Range;
function {:constructor} $Range(lb: int, ub: int): $Range;

function {:inline} $IsValid'bool'(v: bool): bool {
  true
}

function $IsValid'u8'(v: int): bool {
  v >= 0 && v <= $MAX_U8
}

function $IsValid'u64'(v: int): bool {
  v >= 0 && v <= $MAX_U64
}

function $IsValid'u128'(v: int): bool {
  v >= 0 && v <= $MAX_U128
}

function $IsValid'num'(v: int): bool {
  true
}

function $IsValid'address'(v: int): bool {
  // TODO: restrict max to representable addresses?
  v >= 0
}

function {:inline} $IsValidRange(r: $Range): bool {
   $IsValid'u64'(lb#$Range(r)) &&  $IsValid'u64'(ub#$Range(r))
}

// Intentionally not inlined so it serves as a trigger in quantifiers.
function $InRange(r: $Range, i: int): bool {
   lb#$Range(r) <= i && i < ub#$Range(r)
}


function {:inline} $IsEqual'u8'(x: int, y: int): bool {
    x == y
}

function {:inline} $IsEqual'u64'(x: int, y: int): bool {
    x == y
}

function {:inline} $IsEqual'u128'(x: int, y: int): bool {
    x == y
}

function {:inline} $IsEqual'num'(x: int, y: int): bool {
    x == y
}

function {:inline} $IsEqual'address'(x: int, y: int): bool {
    x == y
}

function {:inline} $IsEqual'bool'(x: bool, y: bool): bool {
    x == y
}

// ============================================================================================
// Memory

type {:datatype} $Location;

// A global resource location within the statically known resource type's memory,
// where `a` is an address.
function {:constructor} $Global(a: int): $Location;

// A local location. `i` is the unique index of the local.
function {:constructor} $Local(i: int): $Location;

// The location of a reference outside of the verification scope, for example, a `&mut` parameter
// of the function being verified. References with these locations don't need to be written back
// when mutation ends.
function {:constructor} $Param(i: int): $Location;

// The location of an uninitialized mutation. Using this to make sure that the location
// will not be equal to any valid mutation locations, i.e., $Local, $Global, or $Param.
function {:constructor} $Uninitialized(): $Location;

// A mutable reference which also carries its current value. Since mutable references
// are single threaded in Move, we can keep them together and treat them as a value
// during mutation until the point they are stored back to their original location.
type {:datatype} $Mutation _;
function {:constructor} $Mutation<T>(l: $Location, p: Vec int, v: T): $Mutation T;

// Representation of memory for a given type.
type {:datatype} $Memory _;
function {:constructor} $Memory<T>(domain: [int]bool, contents: [int]T): $Memory T;

function {:builtin "MapConst"} $ConstMemoryDomain(v: bool): [int]bool;
function {:builtin "MapConst"} $ConstMemoryContent<T>(v: T): [int]T;
axiom $ConstMemoryDomain(false) == (lambda i: int :: false);
axiom $ConstMemoryDomain(true) == (lambda i: int :: true);


// Dereferences a mutation.
function {:inline} $Dereference<T>(ref: $Mutation T): T {
    v#$Mutation(ref)
}

// Update the value of a mutation.
function {:inline} $UpdateMutation<T>(m: $Mutation T, v: T): $Mutation T {
    $Mutation(l#$Mutation(m), p#$Mutation(m), v)
}

function {:inline} $ChildMutation<T1, T2>(m: $Mutation T1, offset: int, v: T2): $Mutation T2 {
    $Mutation(l#$Mutation(m), ExtendVec(p#$Mutation(m), offset), v)
}

// Return true if two mutations share the location and path
function {:inline} $IsSameMutation<T1, T2>(parent: $Mutation T1, child: $Mutation T2 ): bool {
    l#$Mutation(parent) == l#$Mutation(child) && p#$Mutation(parent) == p#$Mutation(child)
}

// Return true if the mutation is a parent of a child which was derived with the given edge offset. This
// is used to implement write-back choices.
function {:inline} $IsParentMutation<T1, T2>(parent: $Mutation T1, edge: int, child: $Mutation T2 ): bool {
    l#$Mutation(parent) == l#$Mutation(child) &&
    (var pp := p#$Mutation(parent);
    (var cp := p#$Mutation(child);
    (var pl := LenVec(pp);
    (var cl := LenVec(cp);
     cl == pl + 1 &&
     (forall i: int:: i >= 0 && i < pl ==> ReadVec(pp, i) ==  ReadVec(cp, i)) &&
     $EdgeMatches(ReadVec(cp, pl), edge)
    ))))
}

// Return true if the mutation is a parent of a child, for hyper edge.
function {:inline} $IsParentMutationHyper<T1, T2>(parent: $Mutation T1, hyper_edge: Vec int, child: $Mutation T2 ): bool {
    l#$Mutation(parent) == l#$Mutation(child) &&
    (var pp := p#$Mutation(parent);
    (var cp := p#$Mutation(child);
    (var pl := LenVec(pp);
    (var cl := LenVec(cp);
    (var el := LenVec(hyper_edge);
     cl == pl + el &&
     (forall i: int:: i >= 0 && i < pl ==> ReadVec(pp, i) == ReadVec(cp, i)) &&
     (forall i: int:: i >= 0 && i < el ==> $EdgeMatches(ReadVec(cp, pl + i), ReadVec(hyper_edge, i)))
    )))))
}

function {:inline} $EdgeMatches(edge: int, edge_pattern: int): bool {
    edge_pattern == -1 // wildcard
    || edge_pattern == edge
}



function {:inline} $SameLocation<T1, T2>(m1: $Mutation T1, m2: $Mutation T2): bool {
    l#$Mutation(m1) == l#$Mutation(m2)
}

function {:inline} $HasGlobalLocation<T>(m: $Mutation T): bool {
    is#$Global(l#$Mutation(m))
}

function {:inline} $HasLocalLocation<T>(m: $Mutation T, idx: int): bool {
    l#$Mutation(m) == $Local(idx)
}

function {:inline} $GlobalLocationAddress<T>(m: $Mutation T): int {
    a#$Global(l#$Mutation(m))
}



// Tests whether resource exists.
function {:inline} $ResourceExists<T>(m: $Memory T, addr: int): bool {
    domain#$Memory(m)[addr]
}

// Obtains Value of given resource.
function {:inline} $ResourceValue<T>(m: $Memory T, addr: int): T {
    contents#$Memory(m)[addr]
}

// Update resource.
function {:inline} $ResourceUpdate<T>(m: $Memory T, a: int, v: T): $Memory T {
    $Memory(domain#$Memory(m)[a := true], contents#$Memory(m)[a := v])
}

// Remove resource.
function {:inline} $ResourceRemove<T>(m: $Memory T, a: int): $Memory T {
    $Memory(domain#$Memory(m)[a := false], contents#$Memory(m))
}

// Copies resource from memory s to m.
function {:inline} $ResourceCopy<T>(m: $Memory T, s: $Memory T, a: int): $Memory T {
    $Memory(domain#$Memory(m)[a := domain#$Memory(s)[a]],
            contents#$Memory(m)[a := contents#$Memory(s)[a]])
}



// ============================================================================================
// Abort Handling

var $abort_flag: bool;
var $abort_code: int;

function {:inline} $process_abort_code(code: int): int {
    code
}

const $EXEC_FAILURE_CODE: int;
axiom $EXEC_FAILURE_CODE == -1;

// TODO(wrwg): currently we map aborts of native functions like those for vectors also to
//   execution failure. This may need to be aligned with what the runtime actually does.

procedure {:inline 1} $ExecFailureAbort() {
    $abort_flag := true;
    $abort_code := $EXEC_FAILURE_CODE;
}

procedure {:inline 1} $Abort(code: int) {
    $abort_flag := true;
    $abort_code := code;
}

function {:inline} $StdError(cat: int, reason: int): int {
    reason * 256 + cat
}

procedure {:inline 1} $InitVerification() {
    // Set abort_flag to false, and havoc abort_code
    $abort_flag := false;
    havoc $abort_code;
    // Initialize event store
    call $InitEventStore();
}

// ============================================================================================
// Instructions


procedure {:inline 1} $CastU8(src: int) returns (dst: int)
{
    if (src > $MAX_U8) {
        call $ExecFailureAbort();
        return;
    }
    dst := src;
}

procedure {:inline 1} $CastU64(src: int) returns (dst: int)
{
    if (src > $MAX_U64) {
        call $ExecFailureAbort();
        return;
    }
    dst := src;
}

procedure {:inline 1} $CastU128(src: int) returns (dst: int)
{
    if (src > $MAX_U128) {
        call $ExecFailureAbort();
        return;
    }
    dst := src;
}

procedure {:inline 1} $AddU8(src1: int, src2: int) returns (dst: int)
{
    if (src1 + src2 > $MAX_U8) {
        call $ExecFailureAbort();
        return;
    }
    dst := src1 + src2;
}

procedure {:inline 1} $AddU64(src1: int, src2: int) returns (dst: int)
{
    if (src1 + src2 > $MAX_U64) {
        call $ExecFailureAbort();
        return;
    }
    dst := src1 + src2;
}

procedure {:inline 1} $AddU64_unchecked(src1: int, src2: int) returns (dst: int)
{
    dst := src1 + src2;
}

procedure {:inline 1} $AddU128(src1: int, src2: int) returns (dst: int)
{
    if (src1 + src2 > $MAX_U128) {
        call $ExecFailureAbort();
        return;
    }
    dst := src1 + src2;
}

procedure {:inline 1} $AddU128_unchecked(src1: int, src2: int) returns (dst: int)
{
    dst := src1 + src2;
}

procedure {:inline 1} $Sub(src1: int, src2: int) returns (dst: int)
{
    if (src1 < src2) {
        call $ExecFailureAbort();
        return;
    }
    dst := src1 - src2;
}

// uninterpreted function to return an undefined value.
function $undefined_int(): int;

// Recursive exponentiation function
// Undefined unless e >=0.  $pow(0,0) is also undefined.
function $pow(n: int, e: int): int {
    if n != 0 && e == 0 then 1
    else if e > 0 then n * $pow(n, e - 1)
    else $undefined_int()
}

function $shl(src1: int, p: int): int {
    src1 * $pow(2, p)
}

function $shr(src1: int, p: int): int {
    src1 div $pow(2, p)
}

// We need to know the size of the destination in order to drop bits
// that have been shifted left more than that, so we have $ShlU8/64/128
procedure {:inline 1} $ShlU8(src1: int, src2: int) returns (dst: int)
{
    var res: int;
    // src2 is a u8
    assume src2 >= 0 && src2 < 256;
    dst := $shl(src1, src2) mod 256;
}

procedure {:inline 1} $ShlU64(src1: int, src2: int) returns (dst: int)
{
    var res: int;
    // src2 is a u8
    assume src2 >= 0 && src2 < 256;
    dst := $shl(src1, src2) mod 18446744073709551616;
}

procedure {:inline 1} $ShlU128(src1: int, src2: int) returns (dst: int)
{
    var res: int;
    // src2 is a u8
    assume src2 >= 0 && src2 < 256;
    dst := $shl(src1, src2) mod 340282366920938463463374607431768211456;
}

// We don't need to know the size of destination, so no $ShrU8, etc.
procedure {:inline 1} $Shr(src1: int, src2: int) returns (dst: int)
{
    var res: int;
    // src2 is a u8
    assume src2 >= 0 && src2 < 256;
    dst := $shr(src1, src2);
}

procedure {:inline 1} $MulU8(src1: int, src2: int) returns (dst: int)
{
    if (src1 * src2 > $MAX_U8) {
        call $ExecFailureAbort();
        return;
    }
    dst := src1 * src2;
}

procedure {:inline 1} $MulU64(src1: int, src2: int) returns (dst: int)
{
    if (src1 * src2 > $MAX_U64) {
        call $ExecFailureAbort();
        return;
    }
    dst := src1 * src2;
}

procedure {:inline 1} $MulU128(src1: int, src2: int) returns (dst: int)
{
    if (src1 * src2 > $MAX_U128) {
        call $ExecFailureAbort();
        return;
    }
    dst := src1 * src2;
}

procedure {:inline 1} $Div(src1: int, src2: int) returns (dst: int)
{
    if (src2 == 0) {
        call $ExecFailureAbort();
        return;
    }
    dst := src1 div src2;
}

procedure {:inline 1} $Mod(src1: int, src2: int) returns (dst: int)
{
    if (src2 == 0) {
        call $ExecFailureAbort();
        return;
    }
    dst := src1 mod src2;
}

procedure {:inline 1} $ArithBinaryUnimplemented(src1: int, src2: int) returns (dst: int);

procedure {:inline 1} $Lt(src1: int, src2: int) returns (dst: bool)
{
    dst := src1 < src2;
}

procedure {:inline 1} $Gt(src1: int, src2: int) returns (dst: bool)
{
    dst := src1 > src2;
}

procedure {:inline 1} $Le(src1: int, src2: int) returns (dst: bool)
{
    dst := src1 <= src2;
}

procedure {:inline 1} $Ge(src1: int, src2: int) returns (dst: bool)
{
    dst := src1 >= src2;
}

procedure {:inline 1} $And(src1: bool, src2: bool) returns (dst: bool)
{
    dst := src1 && src2;
}

procedure {:inline 1} $Or(src1: bool, src2: bool) returns (dst: bool)
{
    dst := src1 || src2;
}

procedure {:inline 1} $Not(src: bool) returns (dst: bool)
{
    dst := !src;
}

// Pack and Unpack are auto-generated for each type T


// ==================================================================================
// Native Vector

function {:inline} $SliceVecByRange<T>(v: Vec T, r: $Range): Vec T {
    SliceVec(v, lb#$Range(r), ub#$Range(r))
}

// ----------------------------------------------------------------------------------
// Native Vector implementation for element type `u8`

// Not inlined. It appears faster this way.
function $IsEqual'vec'u8''(v1: Vec (int), v2: Vec (int)): bool {
    LenVec(v1) == LenVec(v2) &&
    (forall i: int:: InRangeVec(v1, i) ==> $IsEqual'u8'(ReadVec(v1, i), ReadVec(v2, i)))
}

// Not inlined.
function $IsValid'vec'u8''(v: Vec (int)): bool {
    $IsValid'u64'(LenVec(v)) &&
    (forall i: int:: InRangeVec(v, i) ==> $IsValid'u8'(ReadVec(v, i)))
}


function {:inline} $ContainsVec'u8'(v: Vec (int), e: int): bool {
    (exists i: int :: $IsValid'u64'(i) && InRangeVec(v, i) && $IsEqual'u8'(ReadVec(v, i), e))
}

function $IndexOfVec'u8'(v: Vec (int), e: int): int;
axiom (forall v: Vec (int), e: int:: {$IndexOfVec'u8'(v, e)}
    (var i := $IndexOfVec'u8'(v, e);
     if (!$ContainsVec'u8'(v, e)) then i == -1
     else $IsValid'u64'(i) && InRangeVec(v, i) && $IsEqual'u8'(ReadVec(v, i), e) &&
        (forall j: int :: $IsValid'u64'(j) && j >= 0 && j < i ==> !$IsEqual'u8'(ReadVec(v, j), e))));


function {:inline} $RangeVec'u8'(v: Vec (int)): $Range {
    $Range(0, LenVec(v))
}


function {:inline} $EmptyVec'u8'(): Vec (int) {
    EmptyVec()
}

procedure {:inline 1} $1_vector_empty'u8'() returns (v: Vec (int)) {
    v := EmptyVec();
}

function {:inline} $1_vector_$empty'u8'(): Vec (int) {
    EmptyVec()
}

procedure {:inline 1} $1_vector_is_empty'u8'(v: Vec (int)) returns (b: bool) {
    b := IsEmptyVec(v);
}

procedure {:inline 1} $1_vector_push_back'u8'(m: $Mutation (Vec (int)), val: int) returns (m': $Mutation (Vec (int))) {
    m' := $UpdateMutation(m, ExtendVec($Dereference(m), val));
}

function {:inline} $1_vector_$push_back'u8'(v: Vec (int), val: int): Vec (int) {
    ExtendVec(v, val)
}

procedure {:inline 1} $1_vector_pop_back'u8'(m: $Mutation (Vec (int))) returns (e: int, m': $Mutation (Vec (int))) {
    var v: Vec (int);
    var len: int;
    v := $Dereference(m);
    len := LenVec(v);
    if (len == 0) {
        call $ExecFailureAbort();
        return;
    }
    e := ReadVec(v, len-1);
    m' := $UpdateMutation(m, RemoveVec(v));
}

procedure {:inline 1} $1_vector_append'u8'(m: $Mutation (Vec (int)), other: Vec (int)) returns (m': $Mutation (Vec (int))) {
    m' := $UpdateMutation(m, ConcatVec($Dereference(m), other));
}

procedure {:inline 1} $1_vector_reverse'u8'(m: $Mutation (Vec (int))) returns (m': $Mutation (Vec (int))) {
    m' := $UpdateMutation(m, ReverseVec($Dereference(m)));
}

procedure {:inline 1} $1_vector_length'u8'(v: Vec (int)) returns (l: int) {
    l := LenVec(v);
}

function {:inline} $1_vector_$length'u8'(v: Vec (int)): int {
    LenVec(v)
}

procedure {:inline 1} $1_vector_borrow'u8'(v: Vec (int), i: int) returns (dst: int) {
    if (!InRangeVec(v, i)) {
        call $ExecFailureAbort();
        return;
    }
    dst := ReadVec(v, i);
}

function {:inline} $1_vector_$borrow'u8'(v: Vec (int), i: int): int {
    ReadVec(v, i)
}

procedure {:inline 1} $1_vector_borrow_mut'u8'(m: $Mutation (Vec (int)), index: int)
returns (dst: $Mutation (int), m': $Mutation (Vec (int)))
{
    var v: Vec (int);
    v := $Dereference(m);
    if (!InRangeVec(v, index)) {
        call $ExecFailureAbort();
        return;
    }
    dst := $Mutation(l#$Mutation(m), ExtendVec(p#$Mutation(m), index), ReadVec(v, index));
    m' := m;
}

function {:inline} $1_vector_$borrow_mut'u8'(v: Vec (int), i: int): int {
    ReadVec(v, i)
}

procedure {:inline 1} $1_vector_destroy_empty'u8'(v: Vec (int)) {
    if (!IsEmptyVec(v)) {
      call $ExecFailureAbort();
    }
}

procedure {:inline 1} $1_vector_swap'u8'(m: $Mutation (Vec (int)), i: int, j: int) returns (m': $Mutation (Vec (int)))
{
    var v: Vec (int);
    v := $Dereference(m);
    if (!InRangeVec(v, i) || !InRangeVec(v, j)) {
        call $ExecFailureAbort();
        return;
    }
    m' := $UpdateMutation(m, SwapVec(v, i, j));
}

function {:inline} $1_vector_$swap'u8'(v: Vec (int), i: int, j: int): Vec (int) {
    SwapVec(v, i, j)
}

procedure {:inline 1} $1_vector_remove'u8'(m: $Mutation (Vec (int)), i: int) returns (e: int, m': $Mutation (Vec (int)))
{
    var v: Vec (int);

    v := $Dereference(m);

    if (!InRangeVec(v, i)) {
        call $ExecFailureAbort();
        return;
    }
    e := ReadVec(v, i);
    m' := $UpdateMutation(m, RemoveAtVec(v, i));
}

procedure {:inline 1} $1_vector_swap_remove'u8'(m: $Mutation (Vec (int)), i: int) returns (e: int, m': $Mutation (Vec (int)))
{
    var len: int;
    var v: Vec (int);

    v := $Dereference(m);
    len := LenVec(v);
    if (!InRangeVec(v, i)) {
        call $ExecFailureAbort();
        return;
    }
    e := ReadVec(v, i);
    m' := $UpdateMutation(m, RemoveVec(SwapVec(v, i, len-1)));
}

procedure {:inline 1} $1_vector_contains'u8'(v: Vec (int), e: int) returns (res: bool)  {
    res := $ContainsVec'u8'(v, e);
}

procedure {:inline 1}
$1_vector_index_of'u8'(v: Vec (int), e: int) returns (res1: bool, res2: int) {
    res2 := $IndexOfVec'u8'(v, e);
    if (res2 >= 0) {
        res1 := true;
    } else {
        res1 := false;
        res2 := 0;
    }
}


// ==================================================================================
// Native Table

// ==================================================================================
// Native Hash

// Hash is modeled as an otherwise uninterpreted injection.
// In truth, it is not an injection since the domain has greater cardinality
// (arbitrary length vectors) than the co-domain (vectors of length 32).  But it is
// common to assume in code there are no hash collisions in practice.  Fortunately,
// Boogie is not smart enough to recognized that there is an inconsistency.
// FIXME: If we were using a reliable extensional theory of arrays, and if we could use ==
// instead of $IsEqual, we might be able to avoid so many quantified formulas by
// using a sha2_inverse function in the ensures conditions of Hash_sha2_256 to
// assert that sha2/3 are injections without using global quantified axioms.


function $1_hash_sha2(val: Vec int): Vec int;

// This says that Hash_sha2 is bijective.
axiom (forall v1,v2: Vec int :: {$1_hash_sha2(v1), $1_hash_sha2(v2)}
       $IsEqual'vec'u8''(v1, v2) <==> $IsEqual'vec'u8''($1_hash_sha2(v1), $1_hash_sha2(v2)));

procedure $1_hash_sha2_256(val: Vec int) returns (res: Vec int);
ensures res == $1_hash_sha2(val);     // returns Hash_sha2 Value
ensures $IsValid'vec'u8''(res);    // result is a legal vector of U8s.
ensures LenVec(res) == 32;               // result is 32 bytes.

// Spec version of Move native function.
function {:inline} $1_hash_$sha2_256(val: Vec int): Vec int {
    $1_hash_sha2(val)
}

// similarly for Hash_sha3
function $1_hash_sha3(val: Vec int): Vec int;

axiom (forall v1,v2: Vec int :: {$1_hash_sha3(v1), $1_hash_sha3(v2)}
       $IsEqual'vec'u8''(v1, v2) <==> $IsEqual'vec'u8''($1_hash_sha3(v1), $1_hash_sha3(v2)));

procedure $1_hash_sha3_256(val: Vec int) returns (res: Vec int);
ensures res == $1_hash_sha3(val);     // returns Hash_sha3 Value
ensures $IsValid'vec'u8''(res);    // result is a legal vector of U8s.
ensures LenVec(res) == 32;               // result is 32 bytes.

// Spec version of Move native function.
function {:inline} $1_hash_$sha3_256(val: Vec int): Vec int {
    $1_hash_sha3(val)
}

// ==================================================================================
// Native string

// TODO: correct implementation of strings

procedure {:inline 1} $1_string_internal_check_utf8(x: Vec int) returns (r: bool) {
}

procedure {:inline 1} $1_string_internal_sub_string(x: Vec int, i: int, j: int) returns (r: Vec int) {
}

procedure {:inline 1} $1_string_internal_index_of(x: Vec int, y: Vec int) returns (r: int) {
}

procedure {:inline 1} $1_string_internal_is_char_boundary(x: Vec int, i: int) returns (r: bool) {
}




// ==================================================================================
// Native diem_account

procedure {:inline 1} $1_DiemAccount_create_signer(
  addr: int
) returns (signer: $signer) {
    // A signer is currently identical to an address.
    signer := $signer(addr);
}

procedure {:inline 1} $1_DiemAccount_destroy_signer(
  signer: $signer
) {
  return;
}

// ==================================================================================
// Native account

procedure {:inline 1} $1_Account_create_signer(
  addr: int
) returns (signer: $signer) {
    // A signer is currently identical to an address.
    signer := $signer(addr);
}

// ==================================================================================
// Native Signer

type {:datatype} $signer;
function {:constructor} $signer($addr: int): $signer;
function {:inline} $IsValid'signer'(s: $signer): bool {
    $IsValid'address'($addr#$signer(s))
}
function {:inline} $IsEqual'signer'(s1: $signer, s2: $signer): bool {
    s1 == s2
}

procedure {:inline 1} $1_signer_borrow_address(signer: $signer) returns (res: int) {
    res := $addr#$signer(signer);
}

function {:inline} $1_signer_$borrow_address(signer: $signer): int
{
    $addr#$signer(signer)
}

function $1_signer_is_txn_signer(s: $signer): bool;

function $1_signer_is_txn_signer_addr(a: int): bool;


// ==================================================================================
// Native signature

// Signature related functionality is handled via uninterpreted functions. This is sound
// currently because we verify every code path based on signature verification with
// an arbitrary interpretation.

function $1_Signature_$ed25519_validate_pubkey(public_key: Vec int): bool;
function $1_Signature_$ed25519_verify(signature: Vec int, public_key: Vec int, message: Vec int): bool;

// Needed because we do not have extensional equality:
axiom (forall k1, k2: Vec int ::
    {$1_Signature_$ed25519_validate_pubkey(k1), $1_Signature_$ed25519_validate_pubkey(k2)}
    $IsEqual'vec'u8''(k1, k2) ==> $1_Signature_$ed25519_validate_pubkey(k1) == $1_Signature_$ed25519_validate_pubkey(k2));
axiom (forall s1, s2, k1, k2, m1, m2: Vec int ::
    {$1_Signature_$ed25519_verify(s1, k1, m1), $1_Signature_$ed25519_verify(s2, k2, m2)}
    $IsEqual'vec'u8''(s1, s2) && $IsEqual'vec'u8''(k1, k2) && $IsEqual'vec'u8''(m1, m2)
    ==> $1_Signature_$ed25519_verify(s1, k1, m1) == $1_Signature_$ed25519_verify(s2, k2, m2));


procedure {:inline 1} $1_Signature_ed25519_validate_pubkey(public_key: Vec int) returns (res: bool) {
    res := $1_Signature_$ed25519_validate_pubkey(public_key);
}

procedure {:inline 1} $1_Signature_ed25519_verify(
        signature: Vec int, public_key: Vec int, message: Vec int) returns (res: bool) {
    res := $1_Signature_$ed25519_verify(signature, public_key, message);
}


// ==================================================================================
// Native bcs::serialize


// ==================================================================================
// Native Event module



procedure {:inline 1} $InitEventStore() {
}



//==================================
// Begin Translation



// Given Types for Type Parameters

type #0;
function {:inline} $IsEqual'#0'(x1: #0, x2: #0): bool { x1 == x2 }
function {:inline} $IsValid'#0'(x: #0): bool { true }

// fun signer::address_of [baseline] at /Users/tobias/.move/https___github_com_move-language_move_git_aba7070cf6f553f85ac6874da1e3630bbc32e44a/language/move-stdlib/sources/signer.move:12:5+77
procedure {:inline 1} $1_signer_address_of(_$t0: $signer) returns ($ret0: int)
{
    // declare local variables
    var $t1: int;
    var $t2: int;
    var $t0: $signer;
    var $temp_0'address': int;
    var $temp_0'signer': $signer;
    $t0 := _$t0;

    // bytecode translation starts here
    // trace_local[s]($t0) at /Users/tobias/.move/https___github_com_move-language_move_git_aba7070cf6f553f85ac6874da1e3630bbc32e44a/language/move-stdlib/sources/signer.move:12:5+1
    assume {:print "$at(3,389,390)"} true;
    assume {:print "$track_local(0,0,0):", $t0} $t0 == $t0;

    // $t1 := signer::borrow_address($t0) on_abort goto L2 with $t2 at /Users/tobias/.move/https___github_com_move-language_move_git_aba7070cf6f553f85ac6874da1e3630bbc32e44a/language/move-stdlib/sources/signer.move:13:10+17
    assume {:print "$at(3,443,460)"} true;
    call $t1 := $1_signer_borrow_address($t0);
    if ($abort_flag) {
        assume {:print "$at(3,443,460)"} true;
        $t2 := $abort_code;
        assume {:print "$track_abort(0,0):", $t2} $t2 == $t2;
        goto L2;
    }

    // trace_return[0]($t1) at /Users/tobias/.move/https___github_com_move-language_move_git_aba7070cf6f553f85ac6874da1e3630bbc32e44a/language/move-stdlib/sources/signer.move:13:9+18
    assume {:print "$track_return(0,0,0):", $t1} $t1 == $t1;

    // label L1 at /Users/tobias/.move/https___github_com_move-language_move_git_aba7070cf6f553f85ac6874da1e3630bbc32e44a/language/move-stdlib/sources/signer.move:14:5+1
    assume {:print "$at(3,465,466)"} true;
L1:

    // return $t1 at /Users/tobias/.move/https___github_com_move-language_move_git_aba7070cf6f553f85ac6874da1e3630bbc32e44a/language/move-stdlib/sources/signer.move:14:5+1
    assume {:print "$at(3,465,466)"} true;
    $ret0 := $t1;
    return;

    // label L2 at /Users/tobias/.move/https___github_com_move-language_move_git_aba7070cf6f553f85ac6874da1e3630bbc32e44a/language/move-stdlib/sources/signer.move:14:5+1
L2:

    // abort($t2) at /Users/tobias/.move/https___github_com_move-language_move_git_aba7070cf6f553f85ac6874da1e3630bbc32e44a/language/move-stdlib/sources/signer.move:14:5+1
    assume {:print "$at(3,465,466)"} true;
    $abort_code := $t2;
    $abort_flag := true;
    return;

}

// struct BasicCoin::Balance<ManagedCoin::ManagedCoin> at ./sources/BasicCoin.move:17:5+77
type {:datatype} $c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin';
function {:constructor} $c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'($coin: $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin'): $c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin';
function {:inline} $Update'$c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin''_coin(s: $c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin', x: $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin'): $c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin' {
    $c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'(x)
}
function $IsValid'$c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin''(s: $c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'): bool {
    $IsValid'$c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin''($coin#$c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'(s))
}
function {:inline} $IsEqual'$c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin''(s1: $c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin', s2: $c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'): bool {
    s1 == s2
}
var $c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory: $Memory $c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin';

// struct BasicCoin::Balance<#0> at ./sources/BasicCoin.move:17:5+77
type {:datatype} $c0ffee_BasicCoin_Balance'#0';
function {:constructor} $c0ffee_BasicCoin_Balance'#0'($coin: $c0ffee_BasicCoin_Coin'#0'): $c0ffee_BasicCoin_Balance'#0';
function {:inline} $Update'$c0ffee_BasicCoin_Balance'#0''_coin(s: $c0ffee_BasicCoin_Balance'#0', x: $c0ffee_BasicCoin_Coin'#0'): $c0ffee_BasicCoin_Balance'#0' {
    $c0ffee_BasicCoin_Balance'#0'(x)
}
function $IsValid'$c0ffee_BasicCoin_Balance'#0''(s: $c0ffee_BasicCoin_Balance'#0'): bool {
    $IsValid'$c0ffee_BasicCoin_Coin'#0''($coin#$c0ffee_BasicCoin_Balance'#0'(s))
}
function {:inline} $IsEqual'$c0ffee_BasicCoin_Balance'#0''(s1: $c0ffee_BasicCoin_Balance'#0', s2: $c0ffee_BasicCoin_Balance'#0'): bool {
    s1 == s2
}
var $c0ffee_BasicCoin_Balance'#0'_$memory: $Memory $c0ffee_BasicCoin_Balance'#0';

// struct BasicCoin::Coin<ManagedCoin::ManagedCoin> at ./sources/BasicCoin.move:12:5+67
type {:datatype} $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin';
function {:constructor} $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin'($value: int): $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin';
function {:inline} $Update'$c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin''_value(s: $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin', x: int): $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin' {
    $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin'(x)
}
function $IsValid'$c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin''(s: $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin'): bool {
    $IsValid'u64'($value#$c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin'(s))
}
function {:inline} $IsEqual'$c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin''(s1: $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin', s2: $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin'): bool {
    s1 == s2
}

// struct BasicCoin::Coin<#0> at ./sources/BasicCoin.move:12:5+67
type {:datatype} $c0ffee_BasicCoin_Coin'#0';
function {:constructor} $c0ffee_BasicCoin_Coin'#0'($value: int): $c0ffee_BasicCoin_Coin'#0';
function {:inline} $Update'$c0ffee_BasicCoin_Coin'#0''_value(s: $c0ffee_BasicCoin_Coin'#0', x: int): $c0ffee_BasicCoin_Coin'#0' {
    $c0ffee_BasicCoin_Coin'#0'(x)
}
function $IsValid'$c0ffee_BasicCoin_Coin'#0''(s: $c0ffee_BasicCoin_Coin'#0'): bool {
    $IsValid'u64'($value#$c0ffee_BasicCoin_Coin'#0'(s))
}
function {:inline} $IsEqual'$c0ffee_BasicCoin_Coin'#0''(s1: $c0ffee_BasicCoin_Coin'#0', s2: $c0ffee_BasicCoin_Coin'#0'): bool {
    s1 == s2
}

// fun BasicCoin::balance_of<ManagedCoin::ManagedCoin> [baseline] at ./sources/BasicCoin.move:42:5+136
procedure {:inline 1} $c0ffee_BasicCoin_balance_of'$c0ffee_ManagedCoin_ManagedCoin'(_$t0: int) returns ($ret0: int)
{
    // declare local variables
    var $t1: $c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin';
    var $t2: int;
    var $t3: $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin';
    var $t4: int;
    var $t0: int;
    var $temp_0'address': int;
    var $temp_0'u64': int;
    $t0 := _$t0;

    // bytecode translation starts here
    // trace_local[owner]($t0) at ./sources/BasicCoin.move:42:5+1
    assume {:print "$at(19,1538,1539)"} true;
    assume {:print "$track_local(1,0,0):", $t0} $t0 == $t0;

    // $t1 := get_global<BasicCoin::Balance<#0>>($t0) on_abort goto L2 with $t2 at ./sources/BasicCoin.move:43:9+13
    assume {:print "$at(19,1618,1631)"} true;
    if (!$ResourceExists($c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory, $t0)) {
        call $ExecFailureAbort();
    } else {
        $t1 := $ResourceValue($c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory, $t0);
    }
    if ($abort_flag) {
        assume {:print "$at(19,1618,1631)"} true;
        $t2 := $abort_code;
        assume {:print "$track_abort(1,0):", $t2} $t2 == $t2;
        goto L2;
    }

    // $t3 := get_field<BasicCoin::Balance<#0>>.coin($t1) at ./sources/BasicCoin.move:43:9+44
    $t3 := $coin#$c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'($t1);

    // $t4 := get_field<BasicCoin::Coin<#0>>.value($t3) at ./sources/BasicCoin.move:43:9+50
    $t4 := $value#$c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin'($t3);

    // trace_return[0]($t4) at ./sources/BasicCoin.move:43:9+50
    assume {:print "$track_return(1,0,0):", $t4} $t4 == $t4;

    // label L1 at ./sources/BasicCoin.move:44:5+1
    assume {:print "$at(19,1673,1674)"} true;
L1:

    // return $t4 at ./sources/BasicCoin.move:44:5+1
    assume {:print "$at(19,1673,1674)"} true;
    $ret0 := $t4;
    return;

    // label L2 at ./sources/BasicCoin.move:44:5+1
L2:

    // abort($t2) at ./sources/BasicCoin.move:44:5+1
    assume {:print "$at(19,1673,1674)"} true;
    $abort_code := $t2;
    $abort_flag := true;
    return;

}

// fun BasicCoin::balance_of<#0> [baseline] at ./sources/BasicCoin.move:42:5+136
procedure {:inline 1} $c0ffee_BasicCoin_balance_of'#0'(_$t0: int) returns ($ret0: int)
{
    // declare local variables
    var $t1: $c0ffee_BasicCoin_Balance'#0';
    var $t2: int;
    var $t3: $c0ffee_BasicCoin_Coin'#0';
    var $t4: int;
    var $t0: int;
    var $temp_0'address': int;
    var $temp_0'u64': int;
    $t0 := _$t0;

    // bytecode translation starts here
    // trace_local[owner]($t0) at ./sources/BasicCoin.move:42:5+1
    assume {:print "$at(19,1538,1539)"} true;
    assume {:print "$track_local(1,0,0):", $t0} $t0 == $t0;

    // $t1 := get_global<BasicCoin::Balance<#0>>($t0) on_abort goto L2 with $t2 at ./sources/BasicCoin.move:43:9+13
    assume {:print "$at(19,1618,1631)"} true;
    if (!$ResourceExists($c0ffee_BasicCoin_Balance'#0'_$memory, $t0)) {
        call $ExecFailureAbort();
    } else {
        $t1 := $ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $t0);
    }
    if ($abort_flag) {
        assume {:print "$at(19,1618,1631)"} true;
        $t2 := $abort_code;
        assume {:print "$track_abort(1,0):", $t2} $t2 == $t2;
        goto L2;
    }

    // $t3 := get_field<BasicCoin::Balance<#0>>.coin($t1) at ./sources/BasicCoin.move:43:9+44
    $t3 := $coin#$c0ffee_BasicCoin_Balance'#0'($t1);

    // $t4 := get_field<BasicCoin::Coin<#0>>.value($t3) at ./sources/BasicCoin.move:43:9+50
    $t4 := $value#$c0ffee_BasicCoin_Coin'#0'($t3);

    // trace_return[0]($t4) at ./sources/BasicCoin.move:43:9+50
    assume {:print "$track_return(1,0,0):", $t4} $t4 == $t4;

    // label L1 at ./sources/BasicCoin.move:44:5+1
    assume {:print "$at(19,1673,1674)"} true;
L1:

    // return $t4 at ./sources/BasicCoin.move:44:5+1
    assume {:print "$at(19,1673,1674)"} true;
    $ret0 := $t4;
    return;

    // label L2 at ./sources/BasicCoin.move:44:5+1
L2:

    // abort($t2) at ./sources/BasicCoin.move:44:5+1
    assume {:print "$at(19,1673,1674)"} true;
    $abort_code := $t2;
    $abort_flag := true;
    return;

}

// fun BasicCoin::balance_of [verification] at ./sources/BasicCoin.move:42:5+136
procedure {:timeLimit 40} $c0ffee_BasicCoin_balance_of$verify(_$t0: int) returns ($ret0: int)
{
    // declare local variables
    var $t1: $c0ffee_BasicCoin_Balance'#0';
    var $t2: int;
    var $t3: $c0ffee_BasicCoin_Coin'#0';
    var $t4: int;
    var $t0: int;
    var $temp_0'address': int;
    var $temp_0'u64': int;
    $t0 := _$t0;

    // verification entrypoint assumptions
    call $InitVerification();

    // bytecode translation starts here
    // assume WellFormed($t0) at ./sources/BasicCoin.move:42:5+1
    assume {:print "$at(19,1538,1539)"} true;
    assume $IsValid'address'($t0);

    // assume forall $rsc: ResourceDomain<BasicCoin::Balance<#0>>(): WellFormed($rsc) at ./sources/BasicCoin.move:42:5+1
    assume (forall $a_0: int :: {$ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $a_0)}(var $rsc := $ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $a_0);
    ($IsValid'$c0ffee_BasicCoin_Balance'#0''($rsc))));

    // trace_local[owner]($t0) at ./sources/BasicCoin.move:42:5+1
    assume {:print "$track_local(1,0,0):", $t0} $t0 == $t0;

    // $t1 := get_global<BasicCoin::Balance<#0>>($t0) on_abort goto L2 with $t2 at ./sources/BasicCoin.move:43:9+13
    assume {:print "$at(19,1618,1631)"} true;
    if (!$ResourceExists($c0ffee_BasicCoin_Balance'#0'_$memory, $t0)) {
        call $ExecFailureAbort();
    } else {
        $t1 := $ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $t0);
    }
    if ($abort_flag) {
        assume {:print "$at(19,1618,1631)"} true;
        $t2 := $abort_code;
        assume {:print "$track_abort(1,0):", $t2} $t2 == $t2;
        goto L2;
    }

    // $t3 := get_field<BasicCoin::Balance<#0>>.coin($t1) at ./sources/BasicCoin.move:43:9+44
    $t3 := $coin#$c0ffee_BasicCoin_Balance'#0'($t1);

    // $t4 := get_field<BasicCoin::Coin<#0>>.value($t3) at ./sources/BasicCoin.move:43:9+50
    $t4 := $value#$c0ffee_BasicCoin_Coin'#0'($t3);

    // trace_return[0]($t4) at ./sources/BasicCoin.move:43:9+50
    assume {:print "$track_return(1,0,0):", $t4} $t4 == $t4;

    // label L1 at ./sources/BasicCoin.move:44:5+1
    assume {:print "$at(19,1673,1674)"} true;
L1:

    // return $t4 at ./sources/BasicCoin.move:44:5+1
    assume {:print "$at(19,1673,1674)"} true;
    $ret0 := $t4;
    return;

    // label L2 at ./sources/BasicCoin.move:44:5+1
L2:

    // abort($t2) at ./sources/BasicCoin.move:44:5+1
    assume {:print "$at(19,1673,1674)"} true;
    $abort_code := $t2;
    $abort_flag := true;
    return;

}

// fun BasicCoin::deposit<ManagedCoin::ManagedCoin> [baseline] at ./sources/BasicCoin.move:63:5+371
procedure {:inline 1} $c0ffee_BasicCoin_deposit'$c0ffee_ManagedCoin_ManagedCoin'(_$t0: int, _$t1: $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin') returns ()
{
    // declare local variables
    var $t2: int;
    var $t3: $Mutation (int);
    var $t4: int;
    var $t5: $Mutation ($c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin');
    var $t6: int;
    var $t7: $Mutation ($c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin');
    var $t8: $Mutation (int);
    var $t9: int;
    var $t10: int;
    var $t0: int;
    var $t1: $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin';
    var $temp_0'$c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin'': $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin';
    var $temp_0'address': int;
    var $temp_0'u64': int;
    $t0 := _$t0;
    $t1 := _$t1;

    // bytecode translation starts here
    // trace_local[_addr]($t0) at ./sources/BasicCoin.move:63:5+1
    assume {:print "$at(19,2527,2528)"} true;
    assume {:print "$track_local(1,1,0):", $t0} $t0 == $t0;

    // trace_local[check]($t1) at ./sources/BasicCoin.move:63:5+1
    assume {:print "$track_local(1,1,1):", $t1} $t1 == $t1;

    // $t4 := unpack BasicCoin::Coin<#0>($t1) at ./sources/BasicCoin.move:65:13+33
    assume {:print "$at(19,2694,2727)"} true;
    $t4 := $value#$c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin'($t1);

    // trace_local[_amount]($t4) at ./sources/BasicCoin.move:65:37+7
    assume {:print "$track_local(1,1,2):", $t4} $t4 == $t4;

    // $t5 := borrow_global<BasicCoin::Balance<#0>>($t0) on_abort goto L2 with $t6 at ./sources/BasicCoin.move:67:32+17
    assume {:print "$at(19,2790,2807)"} true;
    if (!$ResourceExists($c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory, $t0)) {
        call $ExecFailureAbort();
    } else {
        $t5 := $Mutation($Global($t0), EmptyVec(), $ResourceValue($c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory, $t0));
    }
    if ($abort_flag) {
        assume {:print "$at(19,2790,2807)"} true;
        $t6 := $abort_code;
        assume {:print "$track_abort(1,1):", $t6} $t6 == $t6;
        goto L2;
    }

    // $t7 := borrow_field<BasicCoin::Balance<#0>>.coin($t5) at ./sources/BasicCoin.move:67:32+48
    $t7 := $ChildMutation($t5, 0, $coin#$c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'($Dereference($t5)));

    // $t8 := borrow_field<BasicCoin::Coin<#0>>.value($t7) at ./sources/BasicCoin.move:67:27+59
    $t8 := $ChildMutation($t7, 0, $value#$c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin'($Dereference($t7)));

    // trace_local[balance_ref]($t8) at ./sources/BasicCoin.move:67:13+11
    $temp_0'u64' := $Dereference($t8);
    assume {:print "$track_local(1,1,3):", $temp_0'u64'} $temp_0'u64' == $temp_0'u64';

    // $t9 := read_ref($t8) at ./sources/BasicCoin.move:68:24+12
    assume {:print "$at(19,2869,2881)"} true;
    $t9 := $Dereference($t8);

    // $t10 := +($t9, $t4) on_abort goto L2 with $t6 at ./sources/BasicCoin.move:68:37+1
    call $t10 := $AddU64($t9, $t4);
    if ($abort_flag) {
        assume {:print "$at(19,2882,2883)"} true;
        $t6 := $abort_code;
        assume {:print "$track_abort(1,1):", $t6} $t6 == $t6;
        goto L2;
    }

    // write_ref($t8, $t10) at ./sources/BasicCoin.move:68:9+37
    $t8 := $UpdateMutation($t8, $t10);

    // write_back[Reference($t7).value (u64)]($t8) at ./sources/BasicCoin.move:68:9+37
    $t7 := $UpdateMutation($t7, $Update'$c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin''_value($Dereference($t7), $Dereference($t8)));

    // write_back[Reference($t5).coin (BasicCoin::Coin<#0>)]($t7) at ./sources/BasicCoin.move:68:9+37
    $t5 := $UpdateMutation($t5, $Update'$c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin''_coin($Dereference($t5), $Dereference($t7)));

    // write_back[BasicCoin::Balance<#0>@]($t5) at ./sources/BasicCoin.move:68:9+37
    $c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory := $ResourceUpdate($c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory, $GlobalLocationAddress($t5),
        $Dereference($t5));

    // label L1 at ./sources/BasicCoin.move:69:5+1
    assume {:print "$at(19,2897,2898)"} true;
L1:

    // return () at ./sources/BasicCoin.move:69:5+1
    assume {:print "$at(19,2897,2898)"} true;
    return;

    // label L2 at ./sources/BasicCoin.move:69:5+1
L2:

    // abort($t6) at ./sources/BasicCoin.move:69:5+1
    assume {:print "$at(19,2897,2898)"} true;
    $abort_code := $t6;
    $abort_flag := true;
    return;

}

// fun BasicCoin::deposit<#0> [baseline] at ./sources/BasicCoin.move:63:5+371
procedure {:inline 1} $c0ffee_BasicCoin_deposit'#0'(_$t0: int, _$t1: $c0ffee_BasicCoin_Coin'#0') returns ()
{
    // declare local variables
    var $t2: int;
    var $t3: $Mutation (int);
    var $t4: int;
    var $t5: $Mutation ($c0ffee_BasicCoin_Balance'#0');
    var $t6: int;
    var $t7: $Mutation ($c0ffee_BasicCoin_Coin'#0');
    var $t8: $Mutation (int);
    var $t9: int;
    var $t10: int;
    var $t0: int;
    var $t1: $c0ffee_BasicCoin_Coin'#0';
    var $temp_0'$c0ffee_BasicCoin_Coin'#0'': $c0ffee_BasicCoin_Coin'#0';
    var $temp_0'address': int;
    var $temp_0'u64': int;
    $t0 := _$t0;
    $t1 := _$t1;

    // bytecode translation starts here
    // trace_local[_addr]($t0) at ./sources/BasicCoin.move:63:5+1
    assume {:print "$at(19,2527,2528)"} true;
    assume {:print "$track_local(1,1,0):", $t0} $t0 == $t0;

    // trace_local[check]($t1) at ./sources/BasicCoin.move:63:5+1
    assume {:print "$track_local(1,1,1):", $t1} $t1 == $t1;

    // $t4 := unpack BasicCoin::Coin<#0>($t1) at ./sources/BasicCoin.move:65:13+33
    assume {:print "$at(19,2694,2727)"} true;
    $t4 := $value#$c0ffee_BasicCoin_Coin'#0'($t1);

    // trace_local[_amount]($t4) at ./sources/BasicCoin.move:65:37+7
    assume {:print "$track_local(1,1,2):", $t4} $t4 == $t4;

    // $t5 := borrow_global<BasicCoin::Balance<#0>>($t0) on_abort goto L2 with $t6 at ./sources/BasicCoin.move:67:32+17
    assume {:print "$at(19,2790,2807)"} true;
    if (!$ResourceExists($c0ffee_BasicCoin_Balance'#0'_$memory, $t0)) {
        call $ExecFailureAbort();
    } else {
        $t5 := $Mutation($Global($t0), EmptyVec(), $ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $t0));
    }
    if ($abort_flag) {
        assume {:print "$at(19,2790,2807)"} true;
        $t6 := $abort_code;
        assume {:print "$track_abort(1,1):", $t6} $t6 == $t6;
        goto L2;
    }

    // $t7 := borrow_field<BasicCoin::Balance<#0>>.coin($t5) at ./sources/BasicCoin.move:67:32+48
    $t7 := $ChildMutation($t5, 0, $coin#$c0ffee_BasicCoin_Balance'#0'($Dereference($t5)));

    // $t8 := borrow_field<BasicCoin::Coin<#0>>.value($t7) at ./sources/BasicCoin.move:67:27+59
    $t8 := $ChildMutation($t7, 0, $value#$c0ffee_BasicCoin_Coin'#0'($Dereference($t7)));

    // trace_local[balance_ref]($t8) at ./sources/BasicCoin.move:67:13+11
    $temp_0'u64' := $Dereference($t8);
    assume {:print "$track_local(1,1,3):", $temp_0'u64'} $temp_0'u64' == $temp_0'u64';

    // $t9 := read_ref($t8) at ./sources/BasicCoin.move:68:24+12
    assume {:print "$at(19,2869,2881)"} true;
    $t9 := $Dereference($t8);

    // $t10 := +($t9, $t4) on_abort goto L2 with $t6 at ./sources/BasicCoin.move:68:37+1
    call $t10 := $AddU64($t9, $t4);
    if ($abort_flag) {
        assume {:print "$at(19,2882,2883)"} true;
        $t6 := $abort_code;
        assume {:print "$track_abort(1,1):", $t6} $t6 == $t6;
        goto L2;
    }

    // write_ref($t8, $t10) at ./sources/BasicCoin.move:68:9+37
    $t8 := $UpdateMutation($t8, $t10);

    // write_back[Reference($t7).value (u64)]($t8) at ./sources/BasicCoin.move:68:9+37
    $t7 := $UpdateMutation($t7, $Update'$c0ffee_BasicCoin_Coin'#0''_value($Dereference($t7), $Dereference($t8)));

    // write_back[Reference($t5).coin (BasicCoin::Coin<#0>)]($t7) at ./sources/BasicCoin.move:68:9+37
    $t5 := $UpdateMutation($t5, $Update'$c0ffee_BasicCoin_Balance'#0''_coin($Dereference($t5), $Dereference($t7)));

    // write_back[BasicCoin::Balance<#0>@]($t5) at ./sources/BasicCoin.move:68:9+37
    $c0ffee_BasicCoin_Balance'#0'_$memory := $ResourceUpdate($c0ffee_BasicCoin_Balance'#0'_$memory, $GlobalLocationAddress($t5),
        $Dereference($t5));

    // label L1 at ./sources/BasicCoin.move:69:5+1
    assume {:print "$at(19,2897,2898)"} true;
L1:

    // return () at ./sources/BasicCoin.move:69:5+1
    assume {:print "$at(19,2897,2898)"} true;
    return;

    // label L2 at ./sources/BasicCoin.move:69:5+1
L2:

    // abort($t6) at ./sources/BasicCoin.move:69:5+1
    assume {:print "$at(19,2897,2898)"} true;
    $abort_code := $t6;
    $abort_flag := true;
    return;

}

// fun BasicCoin::deposit [verification] at ./sources/BasicCoin.move:63:5+371
procedure {:timeLimit 40} $c0ffee_BasicCoin_deposit$verify(_$t0: int, _$t1: $c0ffee_BasicCoin_Coin'#0') returns ()
{
    // declare local variables
    var $t2: int;
    var $t3: $Mutation (int);
    var $t4: int;
    var $t5: $Mutation ($c0ffee_BasicCoin_Balance'#0');
    var $t6: int;
    var $t7: $Mutation ($c0ffee_BasicCoin_Coin'#0');
    var $t8: $Mutation (int);
    var $t9: int;
    var $t10: int;
    var $t0: int;
    var $t1: $c0ffee_BasicCoin_Coin'#0';
    var $temp_0'$c0ffee_BasicCoin_Coin'#0'': $c0ffee_BasicCoin_Coin'#0';
    var $temp_0'address': int;
    var $temp_0'u64': int;
    $t0 := _$t0;
    $t1 := _$t1;

    // verification entrypoint assumptions
    call $InitVerification();

    // bytecode translation starts here
    // assume WellFormed($t0) at ./sources/BasicCoin.move:63:5+1
    assume {:print "$at(19,2527,2528)"} true;
    assume $IsValid'address'($t0);

    // assume WellFormed($t1) at ./sources/BasicCoin.move:63:5+1
    assume $IsValid'$c0ffee_BasicCoin_Coin'#0''($t1);

    // assume forall $rsc: ResourceDomain<BasicCoin::Balance<#0>>(): WellFormed($rsc) at ./sources/BasicCoin.move:63:5+1
    assume (forall $a_0: int :: {$ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $a_0)}(var $rsc := $ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $a_0);
    ($IsValid'$c0ffee_BasicCoin_Balance'#0''($rsc))));

    // trace_local[_addr]($t0) at ./sources/BasicCoin.move:63:5+1
    assume {:print "$track_local(1,1,0):", $t0} $t0 == $t0;

    // trace_local[check]($t1) at ./sources/BasicCoin.move:63:5+1
    assume {:print "$track_local(1,1,1):", $t1} $t1 == $t1;

    // $t4 := unpack BasicCoin::Coin<#0>($t1) at ./sources/BasicCoin.move:65:13+33
    assume {:print "$at(19,2694,2727)"} true;
    $t4 := $value#$c0ffee_BasicCoin_Coin'#0'($t1);

    // trace_local[_amount]($t4) at ./sources/BasicCoin.move:65:37+7
    assume {:print "$track_local(1,1,2):", $t4} $t4 == $t4;

    // $t5 := borrow_global<BasicCoin::Balance<#0>>($t0) on_abort goto L2 with $t6 at ./sources/BasicCoin.move:67:32+17
    assume {:print "$at(19,2790,2807)"} true;
    if (!$ResourceExists($c0ffee_BasicCoin_Balance'#0'_$memory, $t0)) {
        call $ExecFailureAbort();
    } else {
        $t5 := $Mutation($Global($t0), EmptyVec(), $ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $t0));
    }
    if ($abort_flag) {
        assume {:print "$at(19,2790,2807)"} true;
        $t6 := $abort_code;
        assume {:print "$track_abort(1,1):", $t6} $t6 == $t6;
        goto L2;
    }

    // $t7 := borrow_field<BasicCoin::Balance<#0>>.coin($t5) at ./sources/BasicCoin.move:67:32+48
    $t7 := $ChildMutation($t5, 0, $coin#$c0ffee_BasicCoin_Balance'#0'($Dereference($t5)));

    // $t8 := borrow_field<BasicCoin::Coin<#0>>.value($t7) at ./sources/BasicCoin.move:67:27+59
    $t8 := $ChildMutation($t7, 0, $value#$c0ffee_BasicCoin_Coin'#0'($Dereference($t7)));

    // trace_local[balance_ref]($t8) at ./sources/BasicCoin.move:67:13+11
    $temp_0'u64' := $Dereference($t8);
    assume {:print "$track_local(1,1,3):", $temp_0'u64'} $temp_0'u64' == $temp_0'u64';

    // $t9 := read_ref($t8) at ./sources/BasicCoin.move:68:24+12
    assume {:print "$at(19,2869,2881)"} true;
    $t9 := $Dereference($t8);

    // $t10 := +($t9, $t4) on_abort goto L2 with $t6 at ./sources/BasicCoin.move:68:37+1
    call $t10 := $AddU64($t9, $t4);
    if ($abort_flag) {
        assume {:print "$at(19,2882,2883)"} true;
        $t6 := $abort_code;
        assume {:print "$track_abort(1,1):", $t6} $t6 == $t6;
        goto L2;
    }

    // write_ref($t8, $t10) at ./sources/BasicCoin.move:68:9+37
    $t8 := $UpdateMutation($t8, $t10);

    // write_back[Reference($t7).value (u64)]($t8) at ./sources/BasicCoin.move:68:9+37
    $t7 := $UpdateMutation($t7, $Update'$c0ffee_BasicCoin_Coin'#0''_value($Dereference($t7), $Dereference($t8)));

    // write_back[Reference($t5).coin (BasicCoin::Coin<#0>)]($t7) at ./sources/BasicCoin.move:68:9+37
    $t5 := $UpdateMutation($t5, $Update'$c0ffee_BasicCoin_Balance'#0''_coin($Dereference($t5), $Dereference($t7)));

    // write_back[BasicCoin::Balance<#0>@]($t5) at ./sources/BasicCoin.move:68:9+37
    $c0ffee_BasicCoin_Balance'#0'_$memory := $ResourceUpdate($c0ffee_BasicCoin_Balance'#0'_$memory, $GlobalLocationAddress($t5),
        $Dereference($t5));

    // label L1 at ./sources/BasicCoin.move:69:5+1
    assume {:print "$at(19,2897,2898)"} true;
L1:

    // return () at ./sources/BasicCoin.move:69:5+1
    assume {:print "$at(19,2897,2898)"} true;
    return;

    // label L2 at ./sources/BasicCoin.move:69:5+1
L2:

    // abort($t6) at ./sources/BasicCoin.move:69:5+1
    assume {:print "$at(19,2897,2898)"} true;
    $abort_code := $t6;
    $abort_flag := true;
    return;

}

// fun BasicCoin::mint<ManagedCoin::ManagedCoin> [baseline] at ./sources/BasicCoin.move:33:5+385
procedure {:inline 1} $c0ffee_BasicCoin_mint'$c0ffee_ManagedCoin_ManagedCoin'(_$t0: $signer, _$t1: int, _$t2: int) returns ()
{
    // declare local variables
    var $t3: int;
    var $t4: int;
    var $t5: int;
    var $t6: bool;
    var $t7: int;
    var $t8: $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin';
    var $t0: $signer;
    var $t1: int;
    var $t2: int;
    var $temp_0'address': int;
    var $temp_0'signer': $signer;
    var $temp_0'u64': int;
    $t0 := _$t0;
    $t1 := _$t1;
    $t2 := _$t2;

    // bytecode translation starts here
    // trace_local[module_owner]($t0) at ./sources/BasicCoin.move:33:5+1
    assume {:print "$at(19,1107,1108)"} true;
    assume {:print "$track_local(1,2,0):", $t0} $t0 == $t0;

    // trace_local[mint_addr]($t1) at ./sources/BasicCoin.move:33:5+1
    assume {:print "$track_local(1,2,1):", $t1} $t1 == $t1;

    // trace_local[amount]($t2) at ./sources/BasicCoin.move:33:5+1
    assume {:print "$track_local(1,2,2):", $t2} $t2 == $t2;

    // $t3 := signer::address_of($t0) on_abort goto L3 with $t4 at ./sources/BasicCoin.move:35:17+32
    assume {:print "$at(19,1291,1323)"} true;
    call $t3 := $1_signer_address_of($t0);
    if ($abort_flag) {
        assume {:print "$at(19,1291,1323)"} true;
        $t4 := $abort_code;
        assume {:print "$track_abort(1,2):", $t4} $t4 == $t4;
        goto L3;
    }

    // $t5 := 0xc0ffee at ./sources/BasicCoin.move:35:53+12
    $t5 := 12648430;
    assume $IsValid'address'($t5);

    // $t6 := ==($t3, $t5) at ./sources/BasicCoin.move:35:50+2
    $t6 := $IsEqual'address'($t3, $t5);

    // if ($t6) goto L0 else goto L1 at ./sources/BasicCoin.move:35:9+76
    if ($t6) { goto L0; } else { goto L1; }

    // label L1 at ./sources/BasicCoin.move:35:67+17
L1:

    // $t7 := 0 at ./sources/BasicCoin.move:35:67+17
    assume {:print "$at(19,1341,1358)"} true;
    $t7 := 0;
    assume $IsValid'u64'($t7);

    // trace_abort($t7) at ./sources/BasicCoin.move:35:9+76
    assume {:print "$at(19,1283,1359)"} true;
    assume {:print "$track_abort(1,2):", $t7} $t7 == $t7;

    // $t4 := move($t7) at ./sources/BasicCoin.move:35:9+76
    $t4 := $t7;

    // goto L3 at ./sources/BasicCoin.move:35:9+76
    goto L3;

    // label L0 at ./sources/BasicCoin.move:38:17+9
    assume {:print "$at(19,1441,1450)"} true;
L0:

    // $t8 := pack BasicCoin::Coin<#0>($t2) at ./sources/BasicCoin.move:38:28+32
    assume {:print "$at(19,1452,1484)"} true;
    $t8 := $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin'($t2);

    // BasicCoin::deposit<#0>($t1, $t8) on_abort goto L3 with $t4 at ./sources/BasicCoin.move:38:9+52
    call $c0ffee_BasicCoin_deposit'$c0ffee_ManagedCoin_ManagedCoin'($t1, $t8);
    if ($abort_flag) {
        assume {:print "$at(19,1433,1485)"} true;
        $t4 := $abort_code;
        assume {:print "$track_abort(1,2):", $t4} $t4 == $t4;
        goto L3;
    }

    // label L2 at ./sources/BasicCoin.move:39:5+1
    assume {:print "$at(19,1491,1492)"} true;
L2:

    // return () at ./sources/BasicCoin.move:39:5+1
    assume {:print "$at(19,1491,1492)"} true;
    return;

    // label L3 at ./sources/BasicCoin.move:39:5+1
L3:

    // abort($t4) at ./sources/BasicCoin.move:39:5+1
    assume {:print "$at(19,1491,1492)"} true;
    $abort_code := $t4;
    $abort_flag := true;
    return;

}

// fun BasicCoin::mint [verification] at ./sources/BasicCoin.move:33:5+385
procedure {:timeLimit 40} $c0ffee_BasicCoin_mint$verify(_$t0: $signer, _$t1: int, _$t2: int) returns ()
{
    // declare local variables
    var $t3: int;
    var $t4: int;
    var $t5: int;
    var $t6: bool;
    var $t7: int;
    var $t8: $c0ffee_BasicCoin_Coin'#0';
    var $t0: $signer;
    var $t1: int;
    var $t2: int;
    var $temp_0'address': int;
    var $temp_0'signer': $signer;
    var $temp_0'u64': int;
    $t0 := _$t0;
    $t1 := _$t1;
    $t2 := _$t2;

    // verification entrypoint assumptions
    call $InitVerification();

    // bytecode translation starts here
    // assume WellFormed($t0) at ./sources/BasicCoin.move:33:5+1
    assume {:print "$at(19,1107,1108)"} true;
    assume $IsValid'signer'($t0) && $1_signer_is_txn_signer($t0) && $1_signer_is_txn_signer_addr($addr#$signer($t0));

    // assume WellFormed($t1) at ./sources/BasicCoin.move:33:5+1
    assume $IsValid'address'($t1);

    // assume WellFormed($t2) at ./sources/BasicCoin.move:33:5+1
    assume $IsValid'u64'($t2);

    // assume forall $rsc: ResourceDomain<BasicCoin::Balance<#0>>(): WellFormed($rsc) at ./sources/BasicCoin.move:33:5+1
    assume (forall $a_0: int :: {$ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $a_0)}(var $rsc := $ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $a_0);
    ($IsValid'$c0ffee_BasicCoin_Balance'#0''($rsc))));

    // trace_local[module_owner]($t0) at ./sources/BasicCoin.move:33:5+1
    assume {:print "$track_local(1,2,0):", $t0} $t0 == $t0;

    // trace_local[mint_addr]($t1) at ./sources/BasicCoin.move:33:5+1
    assume {:print "$track_local(1,2,1):", $t1} $t1 == $t1;

    // trace_local[amount]($t2) at ./sources/BasicCoin.move:33:5+1
    assume {:print "$track_local(1,2,2):", $t2} $t2 == $t2;

    // $t3 := signer::address_of($t0) on_abort goto L3 with $t4 at ./sources/BasicCoin.move:35:17+32
    assume {:print "$at(19,1291,1323)"} true;
    call $t3 := $1_signer_address_of($t0);
    if ($abort_flag) {
        assume {:print "$at(19,1291,1323)"} true;
        $t4 := $abort_code;
        assume {:print "$track_abort(1,2):", $t4} $t4 == $t4;
        goto L3;
    }

    // $t5 := 0xc0ffee at ./sources/BasicCoin.move:35:53+12
    $t5 := 12648430;
    assume $IsValid'address'($t5);

    // $t6 := ==($t3, $t5) at ./sources/BasicCoin.move:35:50+2
    $t6 := $IsEqual'address'($t3, $t5);

    // if ($t6) goto L0 else goto L1 at ./sources/BasicCoin.move:35:9+76
    if ($t6) { goto L0; } else { goto L1; }

    // label L1 at ./sources/BasicCoin.move:35:67+17
L1:

    // $t7 := 0 at ./sources/BasicCoin.move:35:67+17
    assume {:print "$at(19,1341,1358)"} true;
    $t7 := 0;
    assume $IsValid'u64'($t7);

    // trace_abort($t7) at ./sources/BasicCoin.move:35:9+76
    assume {:print "$at(19,1283,1359)"} true;
    assume {:print "$track_abort(1,2):", $t7} $t7 == $t7;

    // $t4 := move($t7) at ./sources/BasicCoin.move:35:9+76
    $t4 := $t7;

    // goto L3 at ./sources/BasicCoin.move:35:9+76
    goto L3;

    // label L0 at ./sources/BasicCoin.move:38:17+9
    assume {:print "$at(19,1441,1450)"} true;
L0:

    // $t8 := pack BasicCoin::Coin<#0>($t2) at ./sources/BasicCoin.move:38:28+32
    assume {:print "$at(19,1452,1484)"} true;
    $t8 := $c0ffee_BasicCoin_Coin'#0'($t2);

    // BasicCoin::deposit<#0>($t1, $t8) on_abort goto L3 with $t4 at ./sources/BasicCoin.move:38:9+52
    call $c0ffee_BasicCoin_deposit'#0'($t1, $t8);
    if ($abort_flag) {
        assume {:print "$at(19,1433,1485)"} true;
        $t4 := $abort_code;
        assume {:print "$track_abort(1,2):", $t4} $t4 == $t4;
        goto L3;
    }

    // label L2 at ./sources/BasicCoin.move:39:5+1
    assume {:print "$at(19,1491,1492)"} true;
L2:

    // return () at ./sources/BasicCoin.move:39:5+1
    assume {:print "$at(19,1491,1492)"} true;
    return;

    // label L3 at ./sources/BasicCoin.move:39:5+1
L3:

    // abort($t4) at ./sources/BasicCoin.move:39:5+1
    assume {:print "$at(19,1491,1492)"} true;
    $abort_code := $t4;
    $abort_flag := true;
    return;

}

// fun BasicCoin::publish_balance<ManagedCoin::ManagedCoin> [baseline] at ./sources/BasicCoin.move:23:5+414
procedure {:inline 1} $c0ffee_BasicCoin_publish_balance'$c0ffee_ManagedCoin_ManagedCoin'(_$t0: $signer) returns ()
{
    // declare local variables
    var $t1: $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin';
    var $t2: int;
    var $t3: int;
    var $t4: int;
    var $t5: bool;
    var $t6: bool;
    var $t7: int;
    var $t8: int;
    var $t9: $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin';
    var $t10: $c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin';
    var $t0: $signer;
    var $temp_0'address': int;
    var $temp_0'signer': $signer;
    $t0 := _$t0;

    // bytecode translation starts here
    // trace_local[account]($t0) at ./sources/BasicCoin.move:23:5+1
    assume {:print "$at(19,655,656)"} true;
    assume {:print "$track_local(1,3,0):", $t0} $t0 == $t0;

    // $t3 := signer::address_of($t0) on_abort goto L3 with $t4 at ./sources/BasicCoin.move:25:26+27
    assume {:print "$at(19,835,862)"} true;
    call $t3 := $1_signer_address_of($t0);
    if ($abort_flag) {
        assume {:print "$at(19,835,862)"} true;
        $t4 := $abort_code;
        assume {:print "$track_abort(1,3):", $t4} $t4 == $t4;
        goto L3;
    }

    // trace_local[pubAddress]($t3) at ./sources/BasicCoin.move:25:13+10
    assume {:print "$track_local(1,3,2):", $t3} $t3 == $t3;

    // $t5 := exists<BasicCoin::Balance<#0>>($t3) at ./sources/BasicCoin.move:26:18+6
    assume {:print "$at(19,881,887)"} true;
    $t5 := $ResourceExists($c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory, $t3);

    // $t6 := !($t5) at ./sources/BasicCoin.move:26:17+1
    call $t6 := $Not($t5);

    // if ($t6) goto L0 else goto L1 at ./sources/BasicCoin.move:26:9+69
    if ($t6) { goto L0; } else { goto L1; }

    // label L1 at ./sources/BasicCoin.move:26:9+69
L1:

    // $t7 := 2 at ./sources/BasicCoin.move:26:57+20
    assume {:print "$at(19,920,940)"} true;
    $t7 := 2;
    assume $IsValid'u64'($t7);

    // trace_abort($t7) at ./sources/BasicCoin.move:26:9+69
    assume {:print "$at(19,872,941)"} true;
    assume {:print "$track_abort(1,3):", $t7} $t7 == $t7;

    // $t4 := move($t7) at ./sources/BasicCoin.move:26:9+69
    $t4 := $t7;

    // goto L3 at ./sources/BasicCoin.move:26:9+69
    goto L3;

    // label L0 at ./sources/BasicCoin.move:29:17+7
    assume {:print "$at(19,1014,1021)"} true;
L0:

    // $t8 := 0 at ./sources/BasicCoin.move:28:50+1
    assume {:print "$at(19,993,994)"} true;
    $t8 := 0;
    assume $IsValid'u64'($t8);

    // $t9 := pack BasicCoin::Coin<#0>($t8) at ./sources/BasicCoin.move:28:26+27
    $t9 := $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin'($t8);

    // $t10 := pack BasicCoin::Balance<#0>($t9) at ./sources/BasicCoin.move:29:26+38
    assume {:print "$at(19,1023,1061)"} true;
    $t10 := $c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'($t9);

    // move_to<BasicCoin::Balance<#0>>($t10, $t0) on_abort goto L3 with $t4 at ./sources/BasicCoin.move:29:9+7
    if ($ResourceExists($c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory, $addr#$signer($t0))) {
        call $ExecFailureAbort();
    } else {
        $c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory := $ResourceUpdate($c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory, $addr#$signer($t0), $t10);
    }
    if ($abort_flag) {
        assume {:print "$at(19,1006,1013)"} true;
        $t4 := $abort_code;
        assume {:print "$track_abort(1,3):", $t4} $t4 == $t4;
        goto L3;
    }

    // label L2 at ./sources/BasicCoin.move:30:5+1
    assume {:print "$at(19,1068,1069)"} true;
L2:

    // return () at ./sources/BasicCoin.move:30:5+1
    assume {:print "$at(19,1068,1069)"} true;
    return;

    // label L3 at ./sources/BasicCoin.move:30:5+1
L3:

    // abort($t4) at ./sources/BasicCoin.move:30:5+1
    assume {:print "$at(19,1068,1069)"} true;
    $abort_code := $t4;
    $abort_flag := true;
    return;

}

// fun BasicCoin::publish_balance [verification] at ./sources/BasicCoin.move:23:5+414
procedure {:timeLimit 40} $c0ffee_BasicCoin_publish_balance$verify(_$t0: $signer) returns ()
{
    // declare local variables
    var $t1: $c0ffee_BasicCoin_Coin'#0';
    var $t2: int;
    var $t3: int;
    var $t4: int;
    var $t5: bool;
    var $t6: bool;
    var $t7: int;
    var $t8: int;
    var $t9: $c0ffee_BasicCoin_Coin'#0';
    var $t10: $c0ffee_BasicCoin_Balance'#0';
    var $t0: $signer;
    var $temp_0'address': int;
    var $temp_0'signer': $signer;
    $t0 := _$t0;

    // verification entrypoint assumptions
    call $InitVerification();

    // bytecode translation starts here
    // assume WellFormed($t0) at ./sources/BasicCoin.move:23:5+1
    assume {:print "$at(19,655,656)"} true;
    assume $IsValid'signer'($t0) && $1_signer_is_txn_signer($t0) && $1_signer_is_txn_signer_addr($addr#$signer($t0));

    // assume forall $rsc: ResourceDomain<BasicCoin::Balance<#0>>(): WellFormed($rsc) at ./sources/BasicCoin.move:23:5+1
    assume (forall $a_0: int :: {$ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $a_0)}(var $rsc := $ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $a_0);
    ($IsValid'$c0ffee_BasicCoin_Balance'#0''($rsc))));

    // trace_local[account]($t0) at ./sources/BasicCoin.move:23:5+1
    assume {:print "$track_local(1,3,0):", $t0} $t0 == $t0;

    // $t3 := signer::address_of($t0) on_abort goto L3 with $t4 at ./sources/BasicCoin.move:25:26+27
    assume {:print "$at(19,835,862)"} true;
    call $t3 := $1_signer_address_of($t0);
    if ($abort_flag) {
        assume {:print "$at(19,835,862)"} true;
        $t4 := $abort_code;
        assume {:print "$track_abort(1,3):", $t4} $t4 == $t4;
        goto L3;
    }

    // trace_local[pubAddress]($t3) at ./sources/BasicCoin.move:25:13+10
    assume {:print "$track_local(1,3,2):", $t3} $t3 == $t3;

    // $t5 := exists<BasicCoin::Balance<#0>>($t3) at ./sources/BasicCoin.move:26:18+6
    assume {:print "$at(19,881,887)"} true;
    $t5 := $ResourceExists($c0ffee_BasicCoin_Balance'#0'_$memory, $t3);

    // $t6 := !($t5) at ./sources/BasicCoin.move:26:17+1
    call $t6 := $Not($t5);

    // if ($t6) goto L0 else goto L1 at ./sources/BasicCoin.move:26:9+69
    if ($t6) { goto L0; } else { goto L1; }

    // label L1 at ./sources/BasicCoin.move:26:9+69
L1:

    // $t7 := 2 at ./sources/BasicCoin.move:26:57+20
    assume {:print "$at(19,920,940)"} true;
    $t7 := 2;
    assume $IsValid'u64'($t7);

    // trace_abort($t7) at ./sources/BasicCoin.move:26:9+69
    assume {:print "$at(19,872,941)"} true;
    assume {:print "$track_abort(1,3):", $t7} $t7 == $t7;

    // $t4 := move($t7) at ./sources/BasicCoin.move:26:9+69
    $t4 := $t7;

    // goto L3 at ./sources/BasicCoin.move:26:9+69
    goto L3;

    // label L0 at ./sources/BasicCoin.move:29:17+7
    assume {:print "$at(19,1014,1021)"} true;
L0:

    // $t8 := 0 at ./sources/BasicCoin.move:28:50+1
    assume {:print "$at(19,993,994)"} true;
    $t8 := 0;
    assume $IsValid'u64'($t8);

    // $t9 := pack BasicCoin::Coin<#0>($t8) at ./sources/BasicCoin.move:28:26+27
    $t9 := $c0ffee_BasicCoin_Coin'#0'($t8);

    // $t10 := pack BasicCoin::Balance<#0>($t9) at ./sources/BasicCoin.move:29:26+38
    assume {:print "$at(19,1023,1061)"} true;
    $t10 := $c0ffee_BasicCoin_Balance'#0'($t9);

    // move_to<BasicCoin::Balance<#0>>($t10, $t0) on_abort goto L3 with $t4 at ./sources/BasicCoin.move:29:9+7
    if ($ResourceExists($c0ffee_BasicCoin_Balance'#0'_$memory, $addr#$signer($t0))) {
        call $ExecFailureAbort();
    } else {
        $c0ffee_BasicCoin_Balance'#0'_$memory := $ResourceUpdate($c0ffee_BasicCoin_Balance'#0'_$memory, $addr#$signer($t0), $t10);
    }
    if ($abort_flag) {
        assume {:print "$at(19,1006,1013)"} true;
        $t4 := $abort_code;
        assume {:print "$track_abort(1,3):", $t4} $t4 == $t4;
        goto L3;
    }

    // label L2 at ./sources/BasicCoin.move:30:5+1
    assume {:print "$at(19,1068,1069)"} true;
L2:

    // return () at ./sources/BasicCoin.move:30:5+1
    assume {:print "$at(19,1068,1069)"} true;
    return;

    // label L3 at ./sources/BasicCoin.move:30:5+1
L3:

    // abort($t4) at ./sources/BasicCoin.move:30:5+1
    assume {:print "$at(19,1068,1069)"} true;
    $abort_code := $t4;
    $abort_flag := true;
    return;

}

// fun BasicCoin::transfer<ManagedCoin::ManagedCoin> [baseline] at ./sources/BasicCoin.move:47:5+203
procedure {:inline 1} $c0ffee_BasicCoin_transfer'$c0ffee_ManagedCoin_ManagedCoin'(_$t0: $signer, _$t1: int, _$t2: int) returns ()
{
    // declare local variables
    var $t3: $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin';
    var $t4: int;
    var $t5: int;
    var $t6: $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin';
    var $t0: $signer;
    var $t1: int;
    var $t2: int;
    var $temp_0'$c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin'': $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin';
    var $temp_0'address': int;
    var $temp_0'signer': $signer;
    var $temp_0'u64': int;
    $t0 := _$t0;
    $t1 := _$t1;
    $t2 := _$t2;

    // bytecode translation starts here
    // trace_local[from]($t0) at ./sources/BasicCoin.move:47:5+1
    assume {:print "$at(19,1738,1739)"} true;
    assume {:print "$track_local(1,4,0):", $t0} $t0 == $t0;

    // trace_local[to]($t1) at ./sources/BasicCoin.move:47:5+1
    assume {:print "$track_local(1,4,1):", $t1} $t1 == $t1;

    // trace_local[amount]($t2) at ./sources/BasicCoin.move:47:5+1
    assume {:print "$track_local(1,4,2):", $t2} $t2 == $t2;

    // $t4 := signer::address_of($t0) on_abort goto L2 with $t5 at ./sources/BasicCoin.move:48:30+24
    assume {:print "$at(19,1863,1887)"} true;
    call $t4 := $1_signer_address_of($t0);
    if ($abort_flag) {
        assume {:print "$at(19,1863,1887)"} true;
        $t5 := $abort_code;
        assume {:print "$track_abort(1,4):", $t5} $t5 == $t5;
        goto L2;
    }

    // $t6 := BasicCoin::withdraw<#0>($t4, $t2) on_abort goto L2 with $t5 at ./sources/BasicCoin.move:48:21+42
    call $t6 := $c0ffee_BasicCoin_withdraw'$c0ffee_ManagedCoin_ManagedCoin'($t4, $t2);
    if ($abort_flag) {
        assume {:print "$at(19,1854,1896)"} true;
        $t5 := $abort_code;
        assume {:print "$track_abort(1,4):", $t5} $t5 == $t5;
        goto L2;
    }

    // trace_local[check]($t6) at ./sources/BasicCoin.move:48:13+5
    assume {:print "$track_local(1,4,3):", $t6} $t6 == $t6;

    // BasicCoin::deposit<#0>($t1, $t6) on_abort goto L2 with $t5 at ./sources/BasicCoin.move:49:9+28
    assume {:print "$at(19,1906,1934)"} true;
    call $c0ffee_BasicCoin_deposit'$c0ffee_ManagedCoin_ManagedCoin'($t1, $t6);
    if ($abort_flag) {
        assume {:print "$at(19,1906,1934)"} true;
        $t5 := $abort_code;
        assume {:print "$track_abort(1,4):", $t5} $t5 == $t5;
        goto L2;
    }

    // label L1 at ./sources/BasicCoin.move:50:5+1
    assume {:print "$at(19,1940,1941)"} true;
L1:

    // return () at ./sources/BasicCoin.move:50:5+1
    assume {:print "$at(19,1940,1941)"} true;
    return;

    // label L2 at ./sources/BasicCoin.move:50:5+1
L2:

    // abort($t5) at ./sources/BasicCoin.move:50:5+1
    assume {:print "$at(19,1940,1941)"} true;
    $abort_code := $t5;
    $abort_flag := true;
    return;

}

// fun BasicCoin::transfer [verification] at ./sources/BasicCoin.move:47:5+203
procedure {:timeLimit 40} $c0ffee_BasicCoin_transfer$verify(_$t0: $signer, _$t1: int, _$t2: int) returns ()
{
    // declare local variables
    var $t3: $c0ffee_BasicCoin_Coin'#0';
    var $t4: int;
    var $t5: int;
    var $t6: $c0ffee_BasicCoin_Coin'#0';
    var $t0: $signer;
    var $t1: int;
    var $t2: int;
    var $temp_0'$c0ffee_BasicCoin_Coin'#0'': $c0ffee_BasicCoin_Coin'#0';
    var $temp_0'address': int;
    var $temp_0'signer': $signer;
    var $temp_0'u64': int;
    $t0 := _$t0;
    $t1 := _$t1;
    $t2 := _$t2;

    // verification entrypoint assumptions
    call $InitVerification();

    // bytecode translation starts here
    // assume WellFormed($t0) at ./sources/BasicCoin.move:47:5+1
    assume {:print "$at(19,1738,1739)"} true;
    assume $IsValid'signer'($t0) && $1_signer_is_txn_signer($t0) && $1_signer_is_txn_signer_addr($addr#$signer($t0));

    // assume WellFormed($t1) at ./sources/BasicCoin.move:47:5+1
    assume $IsValid'address'($t1);

    // assume WellFormed($t2) at ./sources/BasicCoin.move:47:5+1
    assume $IsValid'u64'($t2);

    // assume forall $rsc: ResourceDomain<BasicCoin::Balance<#0>>(): WellFormed($rsc) at ./sources/BasicCoin.move:47:5+1
    assume (forall $a_0: int :: {$ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $a_0)}(var $rsc := $ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $a_0);
    ($IsValid'$c0ffee_BasicCoin_Balance'#0''($rsc))));

    // trace_local[from]($t0) at ./sources/BasicCoin.move:47:5+1
    assume {:print "$track_local(1,4,0):", $t0} $t0 == $t0;

    // trace_local[to]($t1) at ./sources/BasicCoin.move:47:5+1
    assume {:print "$track_local(1,4,1):", $t1} $t1 == $t1;

    // trace_local[amount]($t2) at ./sources/BasicCoin.move:47:5+1
    assume {:print "$track_local(1,4,2):", $t2} $t2 == $t2;

    // $t4 := signer::address_of($t0) on_abort goto L2 with $t5 at ./sources/BasicCoin.move:48:30+24
    assume {:print "$at(19,1863,1887)"} true;
    call $t4 := $1_signer_address_of($t0);
    if ($abort_flag) {
        assume {:print "$at(19,1863,1887)"} true;
        $t5 := $abort_code;
        assume {:print "$track_abort(1,4):", $t5} $t5 == $t5;
        goto L2;
    }

    // $t6 := BasicCoin::withdraw<#0>($t4, $t2) on_abort goto L2 with $t5 at ./sources/BasicCoin.move:48:21+42
    call $t6 := $c0ffee_BasicCoin_withdraw'#0'($t4, $t2);
    if ($abort_flag) {
        assume {:print "$at(19,1854,1896)"} true;
        $t5 := $abort_code;
        assume {:print "$track_abort(1,4):", $t5} $t5 == $t5;
        goto L2;
    }

    // trace_local[check]($t6) at ./sources/BasicCoin.move:48:13+5
    assume {:print "$track_local(1,4,3):", $t6} $t6 == $t6;

    // BasicCoin::deposit<#0>($t1, $t6) on_abort goto L2 with $t5 at ./sources/BasicCoin.move:49:9+28
    assume {:print "$at(19,1906,1934)"} true;
    call $c0ffee_BasicCoin_deposit'#0'($t1, $t6);
    if ($abort_flag) {
        assume {:print "$at(19,1906,1934)"} true;
        $t5 := $abort_code;
        assume {:print "$track_abort(1,4):", $t5} $t5 == $t5;
        goto L2;
    }

    // label L1 at ./sources/BasicCoin.move:50:5+1
    assume {:print "$at(19,1940,1941)"} true;
L1:

    // return () at ./sources/BasicCoin.move:50:5+1
    assume {:print "$at(19,1940,1941)"} true;
    return;

    // label L2 at ./sources/BasicCoin.move:50:5+1
L2:

    // abort($t5) at ./sources/BasicCoin.move:50:5+1
    assume {:print "$at(19,1940,1941)"} true;
    $abort_code := $t5;
    $abort_flag := true;
    return;

}

// fun BasicCoin::withdraw<ManagedCoin::ManagedCoin> [baseline] at ./sources/BasicCoin.move:53:5+429
procedure {:inline 1} $c0ffee_BasicCoin_withdraw'$c0ffee_ManagedCoin_ManagedCoin'(_$t0: int, _$t1: int) returns ($ret0: $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin')
{
    // declare local variables
    var $t2: int;
    var $t3: $Mutation (int);
    var $t4: int;
    var $t5: int;
    var $t6: bool;
    var $t7: int;
    var $t8: $Mutation ($c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin');
    var $t9: $Mutation ($c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin');
    var $t10: $Mutation (int);
    var $t11: int;
    var $t12: $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin';
    var $t0: int;
    var $t1: int;
    var $temp_0'$c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin'': $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin';
    var $temp_0'address': int;
    var $temp_0'u64': int;
    $t0 := _$t0;
    $t1 := _$t1;

    // bytecode translation starts here
    // trace_local[addr]($t0) at ./sources/BasicCoin.move:53:5+1
    assume {:print "$at(19,2021,2022)"} true;
    assume {:print "$track_local(1,5,0):", $t0} $t0 == $t0;

    // trace_local[amount]($t1) at ./sources/BasicCoin.move:53:5+1
    assume {:print "$track_local(1,5,1):", $t1} $t1 == $t1;

    // $t4 := BasicCoin::balance_of<#0>($t0) on_abort goto L3 with $t5 at ./sources/BasicCoin.move:54:23+26
    assume {:print "$at(19,2130,2156)"} true;
    call $t4 := $c0ffee_BasicCoin_balance_of'$c0ffee_ManagedCoin_ManagedCoin'($t0);
    if ($abort_flag) {
        assume {:print "$at(19,2130,2156)"} true;
        $t5 := $abort_code;
        assume {:print "$track_abort(1,5):", $t5} $t5 == $t5;
        goto L3;
    }

    // trace_local[balance]($t4) at ./sources/BasicCoin.move:54:13+7
    assume {:print "$track_local(1,5,2):", $t4} $t4 == $t4;

    // $t6 := >=($t4, $t1) at ./sources/BasicCoin.move:56:25+2
    assume {:print "$at(19,2242,2244)"} true;
    call $t6 := $Ge($t4, $t1);

    // if ($t6) goto L0 else goto L1 at ./sources/BasicCoin.move:56:9+49
    if ($t6) { goto L0; } else { goto L1; }

    // label L1 at ./sources/BasicCoin.move:56:36+21
L1:

    // $t7 := 1 at ./sources/BasicCoin.move:56:36+21
    assume {:print "$at(19,2253,2274)"} true;
    $t7 := 1;
    assume $IsValid'u64'($t7);

    // trace_abort($t7) at ./sources/BasicCoin.move:56:9+49
    assume {:print "$at(19,2226,2275)"} true;
    assume {:print "$track_abort(1,5):", $t7} $t7 == $t7;

    // $t5 := move($t7) at ./sources/BasicCoin.move:56:9+49
    $t5 := $t7;

    // goto L3 at ./sources/BasicCoin.move:56:9+49
    goto L3;

    // label L0 at ./sources/BasicCoin.move:57:69+4
    assume {:print "$at(19,2345,2349)"} true;
L0:

    // $t8 := borrow_global<BasicCoin::Balance<#0>>($t0) on_abort goto L3 with $t5 at ./sources/BasicCoin.move:57:32+17
    assume {:print "$at(19,2308,2325)"} true;
    if (!$ResourceExists($c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory, $t0)) {
        call $ExecFailureAbort();
    } else {
        $t8 := $Mutation($Global($t0), EmptyVec(), $ResourceValue($c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory, $t0));
    }
    if ($abort_flag) {
        assume {:print "$at(19,2308,2325)"} true;
        $t5 := $abort_code;
        assume {:print "$track_abort(1,5):", $t5} $t5 == $t5;
        goto L3;
    }

    // $t9 := borrow_field<BasicCoin::Balance<#0>>.coin($t8) at ./sources/BasicCoin.move:57:32+47
    $t9 := $ChildMutation($t8, 0, $coin#$c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'($Dereference($t8)));

    // $t10 := borrow_field<BasicCoin::Coin<#0>>.value($t9) at ./sources/BasicCoin.move:57:27+58
    $t10 := $ChildMutation($t9, 0, $value#$c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin'($Dereference($t9)));

    // trace_local[balance_ref]($t10) at ./sources/BasicCoin.move:57:13+11
    $temp_0'u64' := $Dereference($t10);
    assume {:print "$track_local(1,5,3):", $temp_0'u64'} $temp_0'u64' == $temp_0'u64';

    // $t11 := -($t4, $t1) on_abort goto L3 with $t5 at ./sources/BasicCoin.move:58:32+1
    assume {:print "$at(19,2394,2395)"} true;
    call $t11 := $Sub($t4, $t1);
    if ($abort_flag) {
        assume {:print "$at(19,2394,2395)"} true;
        $t5 := $abort_code;
        assume {:print "$track_abort(1,5):", $t5} $t5 == $t5;
        goto L3;
    }

    // write_ref($t10, $t11) at ./sources/BasicCoin.move:58:9+31
    $t10 := $UpdateMutation($t10, $t11);

    // write_back[Reference($t9).value (u64)]($t10) at ./sources/BasicCoin.move:58:9+31
    $t9 := $UpdateMutation($t9, $Update'$c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin''_value($Dereference($t9), $Dereference($t10)));

    // write_back[Reference($t8).coin (BasicCoin::Coin<#0>)]($t9) at ./sources/BasicCoin.move:58:9+31
    $t8 := $UpdateMutation($t8, $Update'$c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin''_coin($Dereference($t8), $Dereference($t9)));

    // write_back[BasicCoin::Balance<#0>@]($t8) at ./sources/BasicCoin.move:58:9+31
    $c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory := $ResourceUpdate($c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory, $GlobalLocationAddress($t8),
        $Dereference($t8));

    // $t12 := pack BasicCoin::Coin<#0>($t1) at ./sources/BasicCoin.move:59:9+32
    assume {:print "$at(19,2412,2444)"} true;
    $t12 := $c0ffee_BasicCoin_Coin'$c0ffee_ManagedCoin_ManagedCoin'($t1);

    // trace_return[0]($t12) at ./sources/BasicCoin.move:59:9+32
    assume {:print "$track_return(1,5,0):", $t12} $t12 == $t12;

    // label L2 at ./sources/BasicCoin.move:60:5+1
    assume {:print "$at(19,2449,2450)"} true;
L2:

    // return $t12 at ./sources/BasicCoin.move:60:5+1
    assume {:print "$at(19,2449,2450)"} true;
    $ret0 := $t12;
    return;

    // label L3 at ./sources/BasicCoin.move:60:5+1
L3:

    // abort($t5) at ./sources/BasicCoin.move:60:5+1
    assume {:print "$at(19,2449,2450)"} true;
    $abort_code := $t5;
    $abort_flag := true;
    return;

}

// fun BasicCoin::withdraw<#0> [baseline] at ./sources/BasicCoin.move:53:5+429
procedure {:inline 1} $c0ffee_BasicCoin_withdraw'#0'(_$t0: int, _$t1: int) returns ($ret0: $c0ffee_BasicCoin_Coin'#0')
{
    // declare local variables
    var $t2: int;
    var $t3: $Mutation (int);
    var $t4: int;
    var $t5: int;
    var $t6: bool;
    var $t7: int;
    var $t8: $Mutation ($c0ffee_BasicCoin_Balance'#0');
    var $t9: $Mutation ($c0ffee_BasicCoin_Coin'#0');
    var $t10: $Mutation (int);
    var $t11: int;
    var $t12: $c0ffee_BasicCoin_Coin'#0';
    var $t0: int;
    var $t1: int;
    var $temp_0'$c0ffee_BasicCoin_Coin'#0'': $c0ffee_BasicCoin_Coin'#0';
    var $temp_0'address': int;
    var $temp_0'u64': int;
    $t0 := _$t0;
    $t1 := _$t1;

    // bytecode translation starts here
    // trace_local[addr]($t0) at ./sources/BasicCoin.move:53:5+1
    assume {:print "$at(19,2021,2022)"} true;
    assume {:print "$track_local(1,5,0):", $t0} $t0 == $t0;

    // trace_local[amount]($t1) at ./sources/BasicCoin.move:53:5+1
    assume {:print "$track_local(1,5,1):", $t1} $t1 == $t1;

    // $t4 := BasicCoin::balance_of<#0>($t0) on_abort goto L3 with $t5 at ./sources/BasicCoin.move:54:23+26
    assume {:print "$at(19,2130,2156)"} true;
    call $t4 := $c0ffee_BasicCoin_balance_of'#0'($t0);
    if ($abort_flag) {
        assume {:print "$at(19,2130,2156)"} true;
        $t5 := $abort_code;
        assume {:print "$track_abort(1,5):", $t5} $t5 == $t5;
        goto L3;
    }

    // trace_local[balance]($t4) at ./sources/BasicCoin.move:54:13+7
    assume {:print "$track_local(1,5,2):", $t4} $t4 == $t4;

    // $t6 := >=($t4, $t1) at ./sources/BasicCoin.move:56:25+2
    assume {:print "$at(19,2242,2244)"} true;
    call $t6 := $Ge($t4, $t1);

    // if ($t6) goto L0 else goto L1 at ./sources/BasicCoin.move:56:9+49
    if ($t6) { goto L0; } else { goto L1; }

    // label L1 at ./sources/BasicCoin.move:56:36+21
L1:

    // $t7 := 1 at ./sources/BasicCoin.move:56:36+21
    assume {:print "$at(19,2253,2274)"} true;
    $t7 := 1;
    assume $IsValid'u64'($t7);

    // trace_abort($t7) at ./sources/BasicCoin.move:56:9+49
    assume {:print "$at(19,2226,2275)"} true;
    assume {:print "$track_abort(1,5):", $t7} $t7 == $t7;

    // $t5 := move($t7) at ./sources/BasicCoin.move:56:9+49
    $t5 := $t7;

    // goto L3 at ./sources/BasicCoin.move:56:9+49
    goto L3;

    // label L0 at ./sources/BasicCoin.move:57:69+4
    assume {:print "$at(19,2345,2349)"} true;
L0:

    // $t8 := borrow_global<BasicCoin::Balance<#0>>($t0) on_abort goto L3 with $t5 at ./sources/BasicCoin.move:57:32+17
    assume {:print "$at(19,2308,2325)"} true;
    if (!$ResourceExists($c0ffee_BasicCoin_Balance'#0'_$memory, $t0)) {
        call $ExecFailureAbort();
    } else {
        $t8 := $Mutation($Global($t0), EmptyVec(), $ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $t0));
    }
    if ($abort_flag) {
        assume {:print "$at(19,2308,2325)"} true;
        $t5 := $abort_code;
        assume {:print "$track_abort(1,5):", $t5} $t5 == $t5;
        goto L3;
    }

    // $t9 := borrow_field<BasicCoin::Balance<#0>>.coin($t8) at ./sources/BasicCoin.move:57:32+47
    $t9 := $ChildMutation($t8, 0, $coin#$c0ffee_BasicCoin_Balance'#0'($Dereference($t8)));

    // $t10 := borrow_field<BasicCoin::Coin<#0>>.value($t9) at ./sources/BasicCoin.move:57:27+58
    $t10 := $ChildMutation($t9, 0, $value#$c0ffee_BasicCoin_Coin'#0'($Dereference($t9)));

    // trace_local[balance_ref]($t10) at ./sources/BasicCoin.move:57:13+11
    $temp_0'u64' := $Dereference($t10);
    assume {:print "$track_local(1,5,3):", $temp_0'u64'} $temp_0'u64' == $temp_0'u64';

    // $t11 := -($t4, $t1) on_abort goto L3 with $t5 at ./sources/BasicCoin.move:58:32+1
    assume {:print "$at(19,2394,2395)"} true;
    call $t11 := $Sub($t4, $t1);
    if ($abort_flag) {
        assume {:print "$at(19,2394,2395)"} true;
        $t5 := $abort_code;
        assume {:print "$track_abort(1,5):", $t5} $t5 == $t5;
        goto L3;
    }

    // write_ref($t10, $t11) at ./sources/BasicCoin.move:58:9+31
    $t10 := $UpdateMutation($t10, $t11);

    // write_back[Reference($t9).value (u64)]($t10) at ./sources/BasicCoin.move:58:9+31
    $t9 := $UpdateMutation($t9, $Update'$c0ffee_BasicCoin_Coin'#0''_value($Dereference($t9), $Dereference($t10)));

    // write_back[Reference($t8).coin (BasicCoin::Coin<#0>)]($t9) at ./sources/BasicCoin.move:58:9+31
    $t8 := $UpdateMutation($t8, $Update'$c0ffee_BasicCoin_Balance'#0''_coin($Dereference($t8), $Dereference($t9)));

    // write_back[BasicCoin::Balance<#0>@]($t8) at ./sources/BasicCoin.move:58:9+31
    $c0ffee_BasicCoin_Balance'#0'_$memory := $ResourceUpdate($c0ffee_BasicCoin_Balance'#0'_$memory, $GlobalLocationAddress($t8),
        $Dereference($t8));

    // $t12 := pack BasicCoin::Coin<#0>($t1) at ./sources/BasicCoin.move:59:9+32
    assume {:print "$at(19,2412,2444)"} true;
    $t12 := $c0ffee_BasicCoin_Coin'#0'($t1);

    // trace_return[0]($t12) at ./sources/BasicCoin.move:59:9+32
    assume {:print "$track_return(1,5,0):", $t12} $t12 == $t12;

    // label L2 at ./sources/BasicCoin.move:60:5+1
    assume {:print "$at(19,2449,2450)"} true;
L2:

    // return $t12 at ./sources/BasicCoin.move:60:5+1
    assume {:print "$at(19,2449,2450)"} true;
    $ret0 := $t12;
    return;

    // label L3 at ./sources/BasicCoin.move:60:5+1
L3:

    // abort($t5) at ./sources/BasicCoin.move:60:5+1
    assume {:print "$at(19,2449,2450)"} true;
    $abort_code := $t5;
    $abort_flag := true;
    return;

}

// fun BasicCoin::withdraw [verification] at ./sources/BasicCoin.move:53:5+429
procedure {:timeLimit 40} $c0ffee_BasicCoin_withdraw$verify(_$t0: int, _$t1: int) returns ($ret0: $c0ffee_BasicCoin_Coin'#0')
{
    // declare local variables
    var $t2: int;
    var $t3: $Mutation (int);
    var $t4: int;
    var $t5: int;
    var $t6: bool;
    var $t7: int;
    var $t8: $Mutation ($c0ffee_BasicCoin_Balance'#0');
    var $t9: $Mutation ($c0ffee_BasicCoin_Coin'#0');
    var $t10: $Mutation (int);
    var $t11: int;
    var $t12: $c0ffee_BasicCoin_Coin'#0';
    var $t0: int;
    var $t1: int;
    var $temp_0'$c0ffee_BasicCoin_Coin'#0'': $c0ffee_BasicCoin_Coin'#0';
    var $temp_0'address': int;
    var $temp_0'u64': int;
    $t0 := _$t0;
    $t1 := _$t1;

    // verification entrypoint assumptions
    call $InitVerification();

    // bytecode translation starts here
    // assume WellFormed($t0) at ./sources/BasicCoin.move:53:5+1
    assume {:print "$at(19,2021,2022)"} true;
    assume $IsValid'address'($t0);

    // assume WellFormed($t1) at ./sources/BasicCoin.move:53:5+1
    assume $IsValid'u64'($t1);

    // assume forall $rsc: ResourceDomain<BasicCoin::Balance<#0>>(): WellFormed($rsc) at ./sources/BasicCoin.move:53:5+1
    assume (forall $a_0: int :: {$ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $a_0)}(var $rsc := $ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $a_0);
    ($IsValid'$c0ffee_BasicCoin_Balance'#0''($rsc))));

    // trace_local[addr]($t0) at ./sources/BasicCoin.move:53:5+1
    assume {:print "$track_local(1,5,0):", $t0} $t0 == $t0;

    // trace_local[amount]($t1) at ./sources/BasicCoin.move:53:5+1
    assume {:print "$track_local(1,5,1):", $t1} $t1 == $t1;

    // $t4 := BasicCoin::balance_of<#0>($t0) on_abort goto L3 with $t5 at ./sources/BasicCoin.move:54:23+26
    assume {:print "$at(19,2130,2156)"} true;
    call $t4 := $c0ffee_BasicCoin_balance_of'#0'($t0);
    if ($abort_flag) {
        assume {:print "$at(19,2130,2156)"} true;
        $t5 := $abort_code;
        assume {:print "$track_abort(1,5):", $t5} $t5 == $t5;
        goto L3;
    }

    // trace_local[balance]($t4) at ./sources/BasicCoin.move:54:13+7
    assume {:print "$track_local(1,5,2):", $t4} $t4 == $t4;

    // $t6 := >=($t4, $t1) at ./sources/BasicCoin.move:56:25+2
    assume {:print "$at(19,2242,2244)"} true;
    call $t6 := $Ge($t4, $t1);

    // if ($t6) goto L0 else goto L1 at ./sources/BasicCoin.move:56:9+49
    if ($t6) { goto L0; } else { goto L1; }

    // label L1 at ./sources/BasicCoin.move:56:36+21
L1:

    // $t7 := 1 at ./sources/BasicCoin.move:56:36+21
    assume {:print "$at(19,2253,2274)"} true;
    $t7 := 1;
    assume $IsValid'u64'($t7);

    // trace_abort($t7) at ./sources/BasicCoin.move:56:9+49
    assume {:print "$at(19,2226,2275)"} true;
    assume {:print "$track_abort(1,5):", $t7} $t7 == $t7;

    // $t5 := move($t7) at ./sources/BasicCoin.move:56:9+49
    $t5 := $t7;

    // goto L3 at ./sources/BasicCoin.move:56:9+49
    goto L3;

    // label L0 at ./sources/BasicCoin.move:57:69+4
    assume {:print "$at(19,2345,2349)"} true;
L0:

    // $t8 := borrow_global<BasicCoin::Balance<#0>>($t0) on_abort goto L3 with $t5 at ./sources/BasicCoin.move:57:32+17
    assume {:print "$at(19,2308,2325)"} true;
    if (!$ResourceExists($c0ffee_BasicCoin_Balance'#0'_$memory, $t0)) {
        call $ExecFailureAbort();
    } else {
        $t8 := $Mutation($Global($t0), EmptyVec(), $ResourceValue($c0ffee_BasicCoin_Balance'#0'_$memory, $t0));
    }
    if ($abort_flag) {
        assume {:print "$at(19,2308,2325)"} true;
        $t5 := $abort_code;
        assume {:print "$track_abort(1,5):", $t5} $t5 == $t5;
        goto L3;
    }

    // $t9 := borrow_field<BasicCoin::Balance<#0>>.coin($t8) at ./sources/BasicCoin.move:57:32+47
    $t9 := $ChildMutation($t8, 0, $coin#$c0ffee_BasicCoin_Balance'#0'($Dereference($t8)));

    // $t10 := borrow_field<BasicCoin::Coin<#0>>.value($t9) at ./sources/BasicCoin.move:57:27+58
    $t10 := $ChildMutation($t9, 0, $value#$c0ffee_BasicCoin_Coin'#0'($Dereference($t9)));

    // trace_local[balance_ref]($t10) at ./sources/BasicCoin.move:57:13+11
    $temp_0'u64' := $Dereference($t10);
    assume {:print "$track_local(1,5,3):", $temp_0'u64'} $temp_0'u64' == $temp_0'u64';

    // $t11 := -($t4, $t1) on_abort goto L3 with $t5 at ./sources/BasicCoin.move:58:32+1
    assume {:print "$at(19,2394,2395)"} true;
    call $t11 := $Sub($t4, $t1);
    if ($abort_flag) {
        assume {:print "$at(19,2394,2395)"} true;
        $t5 := $abort_code;
        assume {:print "$track_abort(1,5):", $t5} $t5 == $t5;
        goto L3;
    }

    // write_ref($t10, $t11) at ./sources/BasicCoin.move:58:9+31
    $t10 := $UpdateMutation($t10, $t11);

    // write_back[Reference($t9).value (u64)]($t10) at ./sources/BasicCoin.move:58:9+31
    $t9 := $UpdateMutation($t9, $Update'$c0ffee_BasicCoin_Coin'#0''_value($Dereference($t9), $Dereference($t10)));

    // write_back[Reference($t8).coin (BasicCoin::Coin<#0>)]($t9) at ./sources/BasicCoin.move:58:9+31
    $t8 := $UpdateMutation($t8, $Update'$c0ffee_BasicCoin_Balance'#0''_coin($Dereference($t8), $Dereference($t9)));

    // write_back[BasicCoin::Balance<#0>@]($t8) at ./sources/BasicCoin.move:58:9+31
    $c0ffee_BasicCoin_Balance'#0'_$memory := $ResourceUpdate($c0ffee_BasicCoin_Balance'#0'_$memory, $GlobalLocationAddress($t8),
        $Dereference($t8));

    // $t12 := pack BasicCoin::Coin<#0>($t1) at ./sources/BasicCoin.move:59:9+32
    assume {:print "$at(19,2412,2444)"} true;
    $t12 := $c0ffee_BasicCoin_Coin'#0'($t1);

    // trace_return[0]($t12) at ./sources/BasicCoin.move:59:9+32
    assume {:print "$track_return(1,5,0):", $t12} $t12 == $t12;

    // label L2 at ./sources/BasicCoin.move:60:5+1
    assume {:print "$at(19,2449,2450)"} true;
L2:

    // return $t12 at ./sources/BasicCoin.move:60:5+1
    assume {:print "$at(19,2449,2450)"} true;
    $ret0 := $t12;
    return;

    // label L3 at ./sources/BasicCoin.move:60:5+1
L3:

    // abort($t5) at ./sources/BasicCoin.move:60:5+1
    assume {:print "$at(19,2449,2450)"} true;
    $abort_code := $t5;
    $abort_flag := true;
    return;

}

// struct ManagedCoin::ManagedCoin at ./sources/ManagedCoin.move:7:5+30
type {:datatype} $c0ffee_ManagedCoin_ManagedCoin;
function {:constructor} $c0ffee_ManagedCoin_ManagedCoin($dummy_field: bool): $c0ffee_ManagedCoin_ManagedCoin;
function {:inline} $Update'$c0ffee_ManagedCoin_ManagedCoin'_dummy_field(s: $c0ffee_ManagedCoin_ManagedCoin, x: bool): $c0ffee_ManagedCoin_ManagedCoin {
    $c0ffee_ManagedCoin_ManagedCoin(x)
}
function $IsValid'$c0ffee_ManagedCoin_ManagedCoin'(s: $c0ffee_ManagedCoin_ManagedCoin): bool {
    $IsValid'bool'($dummy_field#$c0ffee_ManagedCoin_ManagedCoin(s))
}
function {:inline} $IsEqual'$c0ffee_ManagedCoin_ManagedCoin'(s1: $c0ffee_ManagedCoin_ManagedCoin, s2: $c0ffee_ManagedCoin_ManagedCoin): bool {
    s1 == s2
}

// fun ManagedCoin::transfer [verification] at ./sources/ManagedCoin.move:18:5+203
procedure {:timeLimit 40} $c0ffee_ManagedCoin_transfer$verify(_$t0: $signer, _$t1: int, _$t2: int) returns ()
{
    // declare local variables
    var $t3: int;
    var $t4: int;
    var $t5: int;
    var $t6: int;
    var $t7: bool;
    var $t8: int;
    var $t0: $signer;
    var $t1: int;
    var $t2: int;
    var $temp_0'address': int;
    var $temp_0'signer': $signer;
    var $temp_0'u64': int;
    $t0 := _$t0;
    $t1 := _$t1;
    $t2 := _$t2;

    // verification entrypoint assumptions
    call $InitVerification();

    // bytecode translation starts here
    // assume WellFormed($t0) at ./sources/ManagedCoin.move:18:5+1
    assume {:print "$at(4,508,509)"} true;
    assume $IsValid'signer'($t0) && $1_signer_is_txn_signer($t0) && $1_signer_is_txn_signer_addr($addr#$signer($t0));

    // assume WellFormed($t1) at ./sources/ManagedCoin.move:18:5+1
    assume $IsValid'address'($t1);

    // assume WellFormed($t2) at ./sources/ManagedCoin.move:18:5+1
    assume $IsValid'u64'($t2);

    // assume forall $rsc: ResourceDomain<BasicCoin::Balance<ManagedCoin::ManagedCoin>>(): WellFormed($rsc) at ./sources/ManagedCoin.move:18:5+1
    assume (forall $a_0: int :: {$ResourceValue($c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory, $a_0)}(var $rsc := $ResourceValue($c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory, $a_0);
    ($IsValid'$c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin''($rsc))));

    // trace_local[from]($t0) at ./sources/ManagedCoin.move:18:5+1
    assume {:print "$track_local(2,1,0):", $t0} $t0 == $t0;

    // trace_local[to]($t1) at ./sources/ManagedCoin.move:18:5+1
    assume {:print "$track_local(2,1,1):", $t1} $t1 == $t1;

    // trace_local[amount]($t2) at ./sources/ManagedCoin.move:18:5+1
    assume {:print "$track_local(2,1,2):", $t2} $t2 == $t2;

    // $t3 := 2 at ./sources/ManagedCoin.move:20:26+1
    assume {:print "$at(4,627,628)"} true;
    $t3 := 2;
    assume $IsValid'u64'($t3);

    // $t4 := %($t2, $t3) on_abort goto L3 with $t5 at ./sources/ManagedCoin.move:20:24+1
    call $t4 := $Mod($t2, $t3);
    if ($abort_flag) {
        assume {:print "$at(4,625,626)"} true;
        $t5 := $abort_code;
        assume {:print "$track_abort(2,1):", $t5} $t5 == $t5;
        goto L3;
    }

    // $t6 := 1 at ./sources/ManagedCoin.move:20:31+1
    $t6 := 1;
    assume $IsValid'u64'($t6);

    // $t7 := ==($t4, $t6) at ./sources/ManagedCoin.move:20:28+2
    $t7 := $IsEqual'u64'($t4, $t6);

    // if ($t7) goto L0 else goto L1 at ./sources/ManagedCoin.move:20:9+34
    if ($t7) { goto L0; } else { goto L1; }

    // label L1 at ./sources/ManagedCoin.move:20:9+34
L1:

    // $t8 := 0 at ./sources/ManagedCoin.move:20:34+8
    assume {:print "$at(4,635,643)"} true;
    $t8 := 0;
    assume $IsValid'u64'($t8);

    // trace_abort($t8) at ./sources/ManagedCoin.move:20:9+34
    assume {:print "$at(4,610,644)"} true;
    assume {:print "$track_abort(2,1):", $t8} $t8 == $t8;

    // $t5 := move($t8) at ./sources/ManagedCoin.move:20:9+34
    $t5 := $t8;

    // goto L3 at ./sources/ManagedCoin.move:20:9+34
    goto L3;

    // label L0 at ./sources/ManagedCoin.move:21:42+4
    assume {:print "$at(4,687,691)"} true;
L0:

    // BasicCoin::transfer<ManagedCoin::ManagedCoin>($t0, $t1, $t2) on_abort goto L3 with $t5 at ./sources/ManagedCoin.move:21:9+50
    assume {:print "$at(4,654,704)"} true;
    call $c0ffee_BasicCoin_transfer'$c0ffee_ManagedCoin_ManagedCoin'($t0, $t1, $t2);
    if ($abort_flag) {
        assume {:print "$at(4,654,704)"} true;
        $t5 := $abort_code;
        assume {:print "$track_abort(2,1):", $t5} $t5 == $t5;
        goto L3;
    }

    // label L2 at ./sources/ManagedCoin.move:22:5+1
    assume {:print "$at(4,710,711)"} true;
L2:

    // return () at ./sources/ManagedCoin.move:22:5+1
    assume {:print "$at(4,710,711)"} true;
    return;

    // label L3 at ./sources/ManagedCoin.move:22:5+1
L3:

    // abort($t5) at ./sources/ManagedCoin.move:22:5+1
    assume {:print "$at(4,710,711)"} true;
    $abort_code := $t5;
    $abort_flag := true;
    return;

}

// fun ManagedCoin::setup_and_mint [verification] at ./sources/ManagedCoin.move:11:5+246
procedure {:timeLimit 40} $c0ffee_ManagedCoin_setup_and_mint$verify(_$t0: $signer, _$t1: int) returns ()
{
    // declare local variables
    var $t2: int;
    var $t3: int;
    var $t4: int;
    var $t0: $signer;
    var $t1: int;
    var $temp_0'address': int;
    var $temp_0'signer': $signer;
    var $temp_0'u64': int;
    $t0 := _$t0;
    $t1 := _$t1;

    // verification entrypoint assumptions
    call $InitVerification();

    // bytecode translation starts here
    // assume WellFormed($t0) at ./sources/ManagedCoin.move:11:5+1
    assume {:print "$at(4,256,257)"} true;
    assume $IsValid'signer'($t0) && $1_signer_is_txn_signer($t0) && $1_signer_is_txn_signer_addr($addr#$signer($t0));

    // assume WellFormed($t1) at ./sources/ManagedCoin.move:11:5+1
    assume $IsValid'u64'($t1);

    // assume forall $rsc: ResourceDomain<BasicCoin::Balance<ManagedCoin::ManagedCoin>>(): WellFormed($rsc) at ./sources/ManagedCoin.move:11:5+1
    assume (forall $a_0: int :: {$ResourceValue($c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory, $a_0)}(var $rsc := $ResourceValue($c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin'_$memory, $a_0);
    ($IsValid'$c0ffee_BasicCoin_Balance'$c0ffee_ManagedCoin_ManagedCoin''($rsc))));

    // trace_local[account]($t0) at ./sources/ManagedCoin.move:11:5+1
    assume {:print "$track_local(2,0,0):", $t0} $t0 == $t0;

    // trace_local[amount]($t1) at ./sources/ManagedCoin.move:11:5+1
    assume {:print "$track_local(2,0,1):", $t1} $t1 == $t1;

    // BasicCoin::publish_balance<ManagedCoin::ManagedCoin>($t0) on_abort goto L2 with $t3 at ./sources/ManagedCoin.move:12:9+48
    assume {:print "$at(4,323,371)"} true;
    call $c0ffee_BasicCoin_publish_balance'$c0ffee_ManagedCoin_ManagedCoin'($t0);
    if ($abort_flag) {
        assume {:print "$at(4,323,371)"} true;
        $t3 := $abort_code;
        assume {:print "$track_abort(2,0):", $t3} $t3 == $t3;
        goto L2;
    }

    // $t4 := signer::address_of($t0) on_abort goto L2 with $t3 at ./sources/ManagedCoin.move:14:27+27
    assume {:print "$at(4,400,427)"} true;
    call $t4 := $1_signer_address_of($t0);
    if ($abort_flag) {
        assume {:print "$at(4,400,427)"} true;
        $t3 := $abort_code;
        assume {:print "$track_abort(2,0):", $t3} $t3 == $t3;
        goto L2;
    }

    // trace_local[mintAddress]($t4) at ./sources/ManagedCoin.move:14:13+11
    assume {:print "$track_local(2,0,2):", $t4} $t4 == $t4;

    // BasicCoin::mint<ManagedCoin::ManagedCoin>($t0, $t4, $t1) on_abort goto L2 with $t3 at ./sources/ManagedCoin.move:15:9+58
    assume {:print "$at(4,437,495)"} true;
    call $c0ffee_BasicCoin_mint'$c0ffee_ManagedCoin_ManagedCoin'($t0, $t4, $t1);
    if ($abort_flag) {
        assume {:print "$at(4,437,495)"} true;
        $t3 := $abort_code;
        assume {:print "$track_abort(2,0):", $t3} $t3 == $t3;
        goto L2;
    }

    // label L1 at ./sources/ManagedCoin.move:16:5+1
    assume {:print "$at(4,501,502)"} true;
L1:

    // return () at ./sources/ManagedCoin.move:16:5+1
    assume {:print "$at(4,501,502)"} true;
    return;

    // label L2 at ./sources/ManagedCoin.move:16:5+1
L2:

    // abort($t3) at ./sources/ManagedCoin.move:16:5+1
    assume {:print "$at(4,501,502)"} true;
    $abort_code := $t3;
    $abort_flag := true;
    return;

}
