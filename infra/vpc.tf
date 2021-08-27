resource "aws_vpc" "main" {
    cidr_block = "10.32.0.0/16"
}

resource "aws_subnet" "public" {
    for_each = {
        "az1": "10.32.8.0/24",
        "az2": "10.32.9.0/24",
        "az3": "10.32.10.0/24"
    }

    availability_zone = each.key
    cidr_block        = each.value
    vpc_id            = aws_vpc.main.id
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
}
