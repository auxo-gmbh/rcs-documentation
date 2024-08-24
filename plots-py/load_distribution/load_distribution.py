from shared.constants import SIZES, QUEUE_SIZES, FAIL_NOT_FAIL, ALGS
from shared.linear_regression import plot_linear_regressions

INPUT_DIR = 'input/linear_regression'

for run_type in FAIL_NOT_FAIL:
    for node_size in SIZES:
        for queue_size in QUEUE_SIZES:
            input_files = []
            for algorithm in ALGS:
                input_file = f"{algorithm}-n{node_size}-time-qs{queue_size}{run_type}.csv"
                input_files.append(input_file)
            plot_linear_regressions(
                input_files,
                queue_size,
                f"n{node_size}-qs{queue_size}-linear-regression{run_type}",
                'Average queue occupation'
            )
