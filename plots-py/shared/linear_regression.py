import os

import matplotlib.pyplot as plt
import pandas as pd
from sklearn.linear_model import LinearRegression

from shared.plot_style import set_latex_alike_style

INPUT_DIR = 'input/linear_regression'
OUTPUT_DIR = 'output/linear_regression'

EDGE_COLORS = ['brown', 'blue', 'red']
MARKERS = ['o', '^', 's']
LABELS = ['Random', 'ACO', 'Gossips']


def plot_linear_regressions(input_files: [str], queue_size, output_name: str, y_label: str):
    set_latex_alike_style()

    for index, file_name in enumerate(input_files):
        plot_linear_regression(file_name, EDGE_COLORS[index], MARKERS[index], LABELS[index])

    plt.xlabel('Time [min]')
    plt.ylabel(y_label)
    plt.grid(linestyle='--', linewidth=.5)
    plt.ylim(0, int(queue_size))

    plt.legend()

    plt.savefig(os.path.join(OUTPUT_DIR, f'{output_name}.png'))
    plt.clf()


def plot_linear_regression(file_name: str, edge_color: str, marker: str, label: str):
    path = os.path.join(INPUT_DIR, file_name)
    data = pd.read_csv(path, header=0)

    time = data.iloc[1:, 0].values.reshape(-1, 1)
    value = data.iloc[1:, 1].values

    regression = LinearRegression()
    regression.fit(time, value)
    value_prediction = regression.predict(time)

    plt.scatter(time, value, s=10, marker=marker, facecolors='none', edgecolors=edge_color, label=label)
    plt.plot(time, value_prediction, color=edge_color, linewidth=1)
