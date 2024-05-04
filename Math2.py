from math import pow

def get_price_from_sqrt_price_x96(sqrt_price_x96, token0_decimals, token1_decimals):
    # Convert sqrt_price_x96 from uint160 to float
    sqrt_price_x96 = float(sqrt_price_x96)

    # Calculate the price
    price = pow(sqrt_price_x96, 2) / pow(2, 192)

    # Adjust for the token decimals
    price *= pow(10, token0_decimals) / pow(10, token1_decimals)

    return price

# Example usage
sqrt_price_x96_ = 17789323648845401833  # uint160 value
token0_decimals_ = 6  # Decimals of token0
token1_decimals_ = 8  # Decimals of token1

price = get_price_from_sqrt_price_x96(sqrt_price_x96_, token0_decimals_, token1_decimals_)
print(f"The price is: {price:.18f}")


def invert_sqrt_price_x96(sqrt_price_x96, token0_decimals, token1_decimals):
    # Convert sqrt_price_x96 from uint160 to float
    sqrt_price_x96 = float(sqrt_price_x96)

    # Calculate the original price
    price = pow(sqrt_price_x96, 2) / pow(2, 192)

    # Adjust for the token decimals
    price *= pow(10, token0_decimals) / pow(10, token1_decimals)

    # Calculate the inverse price
    inverse_price = 1 / price

    # Adjust the inverse price for the new token decimals
    inverse_price *= pow(10, token1_decimals) / pow(10, token0_decimals)

    # Calculate the new sqrt_price_x96
    new_sqrt_price_x96 = pow(inverse_price * pow(2, 192), 0.5)

    return int(new_sqrt_price_x96)

# Example usage
sqrt_price_x96 = 1891430330361205550005648649065  # uint160 value
token0_decimals = 8  # Decimals of WBTC (token0)
token1_decimals = 6  # Decimals of USDC (token1)

new_sqrt_price_x96 = invert_sqrt_price_x96(sqrt_price_x96, token0_decimals, token1_decimals)
print(f"The new sqrt_price_x96 (USDC/WBTC) is: {new_sqrt_price_x96}")