# -*- coding: utf-8 -*-
"""Unit test cho prototype (khong can nvcc, khong can CUDA)."""
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import tkv_cuda as tc

SAMPLE = os.path.join(os.path.dirname(HERE), "examples", "vecadd.tkv")


class TestCudaBackend(unittest.TestCase):
    def test_parse_two_kernels(self):
        src = open(SAMPLE, encoding="utf-8").read()
        kernels = tc.parse_kernels(src)
        self.assertEqual([k.name for k in kernels], ["vec_add", "scale"])
        self.assertEqual(kernels[0].grid, "(n + 255) // 256")
        self.assertEqual(kernels[0].block, "256")

    def test_annotation_string(self):
        src = open(SAMPLE, encoding="utf-8").read()
        k = tc.parse_kernels(src)[0]
        self.assertEqual(tc.ann_of(k.args[0]), "ptr[f32]")
        self.assertEqual(tc._base_type(tc.ann_of(k.args[0])), "f32")

    def test_generated_cu(self):
        src = open(SAMPLE, encoding="utf-8").read()
        cu = tc.gen_cu(tc.parse_kernels(src))
        self.assertIn('extern "C" __global__ void tkv_kernel_vec_add', cu)
        self.assertIn("blockIdx.x * blockDim.x + threadIdx.x", cu)
        self.assertIn("c[i] = (a[i] + b[i]);", cu)
        self.assertIn("tkv_kernel_vec_add<<<grid, block>>>", cu)
        self.assertIn("cudaGetLastError()", cu)
        self.assertIn("const float* __restrict__ a", cu)   # a chi doc
        self.assertIn("float* __restrict__ c", cu)         # c bi ghi

    def test_generated_glue(self):
        src = open(SAMPLE, encoding="utf-8").read()
        glue = tc.gen_glue(tc.parse_kernels(src), "tkv_cuda_kernels")
        self.assertIn("__tkv_extern_pinvoke__ = [", glue)
        self.assertIn('"symbol": "tkv_launch_vec_add"', glue)
        self.assertIn('"params": ["i64", "i64", "i64", "i32", "i32", "i32"]', glue)
        self.assertIn('def vec_add_launch(', glue)

    def test_strip_and_merge(self):
        src = open(SAMPLE, encoding="utf-8").read()
        kernels = tc.parse_kernels(src)
        host = tc.strip_kernels(src, kernels)
        self.assertNotIn("@tkv.cuda_kernel", host)
        self.assertIn("def run() -> \"i32\":", host)
        merged = tc.merge_pragma(host, tc.gen_glue(kernels, "tkv_cuda_kernels"))
        self.assertIn("__tkv_extern_pinvoke__", merged)
        self.assertIn("def run() -> \"i32\":", merged)

    def test_reject_unsupported_call(self):
        bad = '''# @tkv.cuda_kernel grid="1" block="1"\ndef k(a: "ptr[f32]", n: "i32") -> "void":\n    i = tid()\n    a[i] = strlen(a)\n'''
        with self.assertRaises(SyntaxError):
            tc.CGenerator(tc.parse_kernels(bad)[0]).body()


if __name__ == "__main__":
    unittest.main(verbosity=2)
