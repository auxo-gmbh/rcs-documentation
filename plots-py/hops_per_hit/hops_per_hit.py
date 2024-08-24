from shared.boxplot import plot_boxplot
from shared.constants import FAIL_NOT_FAIL, SIZES, ALGS

for fnf in FAIL_NOT_FAIL:
    for size in SIZES:
        input_array = []
        for alg in ALGS:
            input_array.append(f'{alg}-n{size}-boxplot{fnf}.csv')
        plot_boxplot(f'result-{size}{fnf}-boxplot', input_array, "Hops Per Hit", "Hops Per Hit Boxplot")
