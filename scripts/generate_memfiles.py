from pathlib import Path
from zipfile import ZipFile
import h5py
from shutil import rmtree
import sys
import numpy as np

cd = Path(__file__).resolve().parent

models = {
    "unpruned": "unpruned.keras", 
    "pruned": "pruned_37.5.keras"
}

if len(sys.argv) < 2 or sys.argv[1] not in models:
    print(f"Usage: python {sys.argv[0]} {{{'|'.join(models.keys())}}}")
    sys.exit(-1)

model_keras = cd/".."/"model"/models[sys.argv[1]]

# Keras files are just zip archive, so first we'll unzip them
model_extract = cd/"extracted"
ZipFile(model_keras, "r").extractall(model_extract)

# Read the data from the h5 files
parameters = h5py.File(model_extract/"model.weights.h5")
weights = {}

def extract_layer(path):
    if path[-1] != "0":
        return
    
    dataset = np.asarray(parameters[path]).T
    
    if path.startswith("fc1"):
        weights["first_layer"] = dataset
    elif path.startswith("layers"):
        weights["hidden_layer"] = dataset
    else:
        print(f"Unknown layer type encountered: {path}")
        sys.exit(-1)
    
# Quick and dirty extraction of weigths
parameters.visit(
    lambda x: extract_layer(x)
)

memfiles = cd/".."/"memfiles"
memfiles.mkdir(exist_ok=True)

def binarize_to_memfile(array, path):
    with open(path, 'w') as f:
        for i in range(array.shape[0]):
            # Convert each pixel to binary string of 1 or 0.
            binary_string = ''.join(['1' if x > 0 else '0' for x in array[i]])
            f.write(binary_string + '\n')

for name, weight in weights.items():
    binarize_to_memfile(weight, memfiles/f"{name}.mem")

# Output controller output files: hidden layer count and mask
hidden_layer_width = weights["first_layer"].shape[0]
assert hidden_layer_width % 2 == 0

open(memfiles/"hidden_layer_width.mem", "w").write(f"{(hidden_layer_width-1):08b}\n")

mask_string = ("0" * ((784 - hidden_layer_width)//2)) + ("1" * (hidden_layer_width//2))
assert len(mask_string) == 392
open(memfiles/"mask.mem", "w").write(mask_string)

# Clean up
rmtree(model_extract)

