import unittest

from capacity import serial_capacity


class CapacityTests(unittest.TestCase):
    def test_whole_answers_that_fit(self):
        self.assertEqual(serial_capacity(20, 100, 30), 6)

    def test_rounds_down(self):
        self.assertEqual(serial_capacity(20, 100, 29), 5)

    def test_too_slow_for_even_one_answer(self):
        self.assertEqual(serial_capacity(10, 100, 5), 0)

    def test_bad_inputs(self):
        for arguments in [(0, 100, 30), (20, 0, 30), (20, 100, 0), (-1, 100, 30)]:
            with self.subTest(arguments=arguments):
                with self.assertRaises(ValueError):
                    serial_capacity(*arguments)


if __name__ == "__main__":
    unittest.main()
