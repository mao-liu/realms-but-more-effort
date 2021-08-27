locals {
    tags = {
        "Project" = "realms"
    }

    spot_price_maximum = {
        "t3a.small":  0.0075,   # on demand 0.0238
        "t3a.medium": 0.015,    # on demand 0.0475
        "t3a.large":  0.030,    # on demand 0.095
        "t3a.xlarge": 0.060,    # on demand 0.1901
    }

    instance_type = "t3a.small"
}
