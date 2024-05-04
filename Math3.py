import decimal

def calculate_price(square_root_price_x96, token0_decimals, token1_decimals):
    # Convert the Q96 price to a decimal value
    price_x96 = decimal.Decimal(square_root_price_x96) ** 2 / (2 ** 192)

    # Adjust the price based on the token decimals
    price = price_x96 * (10 ** token0_decimals) / (10 ** token1_decimals)

    return price

# Example usage
square_root_price_x96 = 330966093356031642951483392
token0_decimals = 6
token1_decimals = 8

price = calculate_price(square_root_price_x96, token0_decimals, token1_decimals)
print(f"Price: {price:.18f}")

