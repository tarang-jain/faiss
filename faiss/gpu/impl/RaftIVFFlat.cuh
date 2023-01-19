/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#include <raft/core/handle.hpp>
#include <raft/neighbors/ivf_flat_types.hpp>

#include <faiss/gpu/impl/GpuScalarQuantizer.cuh>
#include <faiss/gpu/impl/IVFFlat.cuh>

#include <optional>

namespace faiss {
namespace gpu {

class RaftIVFFlat : public IVFFlat {
   public:
    RaftIVFFlat(GpuResources* resources,
            int dim,
            int nlist,
            faiss::MetricType metric,
            float metricArg,
            bool useResidual,
            /// Optional ScalarQuantizer
            faiss::ScalarQuantizer* scalarQ,
            bool interleavedLayout,
            IndicesOptions indicesOptions,
            MemorySpace space);

    ~RaftIVFFlat() override;


    /// Find the approximate k nearest neigbors for `queries` against
    /// our database
    void search(
            Index* coarseQuantizer,
            Tensor<float, 2, true>& queries,
            int nprobe,
            int k,
            Tensor<float, 2, true>& outDistances,
            Tensor<idx_t, 2, true>& outIndices) override;

    /// Performs search when we are already given the IVF cells to look at
    /// (GpuIndexIVF::search_preassigned implementation)
    void searchPreassigned(
            Index* coarseQuantizer,
            Tensor<float, 2, true>& vecs,
            Tensor<float, 2, true>& ivfDistances,
            Tensor<idx_t, 2, true>& ivfAssignments,
            int k,
            Tensor<float, 2, true>& outDistances,
            Tensor<idx_t, 2, true>& outIndices,
            bool storePairs) override;

    /// Classify and encode/add vectors to our IVF lists.
    /// The input data must be on our current device.
    /// Returns the number of vectors successfully added. Vectors may
    /// not be able to be added because they contain NaNs.
    int addVectors(
            Index* coarseQuantizer,
            Tensor<float, 2, true>& vecs,
            Tensor<idx_t, 1, true>& indices) override;

    /// Clear out all inverted lists, but retain the coarse quantizer
    /// and the product quantizer info
    void reset() override;

    /// For debugging purposes, return the list length of a particular
    /// list
    int getListLength(int listId) const override;

    /// Return the list indices of a particular list back to the CPU
    std::vector<idx_t> getListIndices(int listId) const override;

    /// Return the encoded vectors of a particular list back to the CPU
    std::vector<uint8_t> getListVectorData(int listId, bool gpuFormat) const override;

    void updateQuantizer(Index* quantizer) override;

//
//    /// Copy all inverted lists from a CPU representation to ourselves
//    void copyInvertedListsFrom(const InvertedLists* ivf) override;
//
//    /// Copy all inverted lists from ourselves to a CPU representation
//    void copyInvertedListsTo(InvertedLists* ivf) override;

   protected:

//    /// Adds a set of codes and indices to a list, with the representation
//    /// coming from the CPU equivalent
//    void addEncodedVectorsToList_(
//            int listId,
//            // resident on the host
//            const void* codes,
//            // resident on the host
//            const Index::idx_t* indices,
//            size_t numVecs) override;


    std::optional<raft::neighbors::ivf_flat::index<float, idx_t>> raft_knn_index{std::nullopt};

};

} // namespace gpu
} // namespace faiss