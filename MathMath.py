import math

def calculate_inverse_square_root_price(sqrt_price_x96, decimals_token0, decimals_token1):
    # Step 1: Convert the original square root price from Q96 format to a decimal value
    sqrt_price = sqrt_price_x96 / (2 ** 96)

    # Step 2: Calculate the original price by squaring the square root price
    price = sqrt_price ** 2

    # Step 3: Adjust the price based on the difference in decimals between token1 and token0
    adjusted_price = price / (10 ** (decimals_token1 - decimals_token0))

    # Step 4: Calculate the inverse price by taking the reciprocal of the adjusted price
    inverse_price = 1 / adjusted_price

    # Step 5: Convert the inverse price to the inverse square root price
    inverse_sqrt_price = math.sqrt(inverse_price)

    # Step 6: Convert the inverse square root price to Q96 format
    inverse_sqrt_price_x96 = int(inverse_sqrt_price * (2 ** 96))

    return inverse_sqrt_price_x96

# Example usage             
original_sqrt_price_x96 =   1896599640082824244384924832921
token0_decimals = 8  # WBTC
token1_decimals = 6  # USDC

# Calculate the inverse square root price
inverse_sqrt_price_x96 = calculate_inverse_square_root_price(original_sqrt_price_x96, token0_decimals, token1_decimals)
print(f"Inverse Square Root Price (Q96): {inverse_sqrt_price_x96}")

# Verify the inverse square root price by calculating the original price
def calculate_price(sqrt_price_x96, decimals_token0, decimals_token1):
    sqrt_price = sqrt_price_x96 / (2 ** 96)
    price = sqrt_price ** 2
    adjusted_price = price / (10 ** (decimals_token1 - decimals_token0))
    return adjusted_price

original_price = calculate_price(original_sqrt_price_x96, token0_decimals, token1_decimals)
print(f"Original Price: {original_price}")

inverse_price = calculate_price(inverse_sqrt_price_x96, token1_decimals, token0_decimals)
print(f"Inverse Price: {inverse_price}")