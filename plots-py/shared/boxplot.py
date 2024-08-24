import os

import matplotlib.pyplot as plt
import pandas as pd

from shared.constants import LATEX_COLORS
from shared.plot_style import set_latex_alike_style

INPUT_DIR = 'input/boxplot'
OUTPUT_DIR = 'output/boxplot'


def plot_boxplot(output_name, file_name_array, ylabel, title):
    result_dict = {}

    for file_name in file_name_array:
        path = os.path.join(INPUT_DIR, file_name)
        data = pd.read_csv(path, header=0)
        value = data.iloc[:, 0].values
        alg = file_name.split('-')[0]
        result_dict[get_name_for_alg(alg)] = value

    set_latex_alike_style()

    bplot = plt.boxplot(result_dict.values(), labels=result_dict.keys(), patch_artist=True)

    for patch, color in zip(bplot["boxes"], LATEX_COLORS):
        patch.set_facecolor(color)

    median_colors = ["brown", "blue", "red"]
    for median, color in zip(bplot["medians"], median_colors):
        median.set_color(color)

    plt.grid(axis='y', linestyle='--')
    plt.ylabel(ylabel)
    plt.title(title)

    plt.savefig(os.path.join(OUTPUT_DIR, f'{output_name}.png'))
    plt.clf()


def get_name_for_alg(alg):
    match alg:
        case "aco":
            return "ACO"
        case "rw":
            return "Random"
        case "gossips":
            return "Gossips"
