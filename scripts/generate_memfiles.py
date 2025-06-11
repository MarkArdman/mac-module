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

if len(sys.argv) < 3 or sys.argv[1] not in models:
    print(f"Usage: python {sys.argv[0]} {{{'|'.join(models.keys())}}} test_number")
    sys.exit(-1)

model_folder = cd/".."/"model"
model_keras = model_folder/models[sys.argv[1]]

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

def binarize_to_memfile_2d(array, f):
    for i in range(array.shape[0]):
        # Convert each pixel to binary string of 1 or 0.
        binary_string = ''.join(['1' if x > 0 else '0' for x in array[i]])
        f.write(binary_string + '\n')

def binarize_to_memfile_1d(array, f):
    # Convert each pixel to binary string of 1 or 0.
    binary_string = ''.join(['1' if x > 0 else '0' for x in array])
    f.write(binary_string + '\n')

hidden_layer_width = weights["first_layer"].shape[0]
assert hidden_layer_width % 2 == 0

# To share the same weight memory, we pad out the hidden layer to have the same width (784)
padded_hidden = np.hstack((weights["hidden_layer"], np.zeros((10, 784-hidden_layer_width))))
# Then we stack them ontop so the state machine can just keep a running sum of which weight row to process next
full_weights = np.vstack((weights["first_layer"], padded_hidden))

binarize_to_memfile_2d(full_weights, open(memfiles/"weights.mem", "w"))

# Output controller output files: hidden layer count and mask
open(memfiles/"hidden_layer_width.mem", "w").write(f"{(hidden_layer_width-1):08b}\n")

mask_string = ("0" * ((784 - hidden_layer_width)//2)) + ("1" * (hidden_layer_width//2))
assert len(mask_string) == 392
open(memfiles/"mask.mem", "w").write(mask_string + "\n")

test_number = int(sys.argv[2])
test_inputs = np.load(model_folder/"test_inputs.npy")
binarize_to_memfile_1d(test_inputs[test_number], open(memfiles/"input.mem", "w"))

expected_output = np.load(model_folder/f"{sys.argv[1]}_expected.npy")[test_number]

print(f"Expected output for model {sys.argv[1]} on test input {test_number}: ", end="")
binarize_to_memfile_1d(expected_output, sys.stdout)

real_output = np.load(model_folder/"correct.npy")[test_number]
print(f"Correct output: {'0' * real_output + '1' + '0' * (9-real_output)}")

# Clean up
rmtree(model_extract)

print("Memfiles generated successfully :)")

