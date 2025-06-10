def write_test_data_to_file(x_test, filename='mem.mem'):
    with open(filename, 'w') as f:
        for i in range(x_test.shape[0]):
            # Convert each pixel to binary string of 1 or 0.
            binary_string = ''.join(['1' if x > 0 else '0' for x in x_test[i]])
            f.write(binary_string + '\n')