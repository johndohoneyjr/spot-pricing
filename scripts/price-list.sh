#! /bin/bash

export REGION="westus"

# build a list of sizes that match our criteria (say 4 cores) ... pick top 10
az vm list-sizes --location ${REGION} --query 'sort_by([?numberOfCores == `4` && !contains(name, `Promo`) && !contains(name, `Standard_B`)], &memoryInMb) | [:9].name' -o json > sizes.json

echo -n 'https://prices.azure.com/api/retail/prices?$filter=serviceName eq "Virtual Machines" and armRegionName eq "' > url.txt
echo -n ${REGION} >> url.txt
echo -n '" and contains(skuName, "Spot") eq true' >> url.txt

# add size constraints to limit price response
jq -re '[.[] | "(armSkuName eq \"" + . + "\")"] | " and (" + join(" or ") + ")"' sizes.json >> url.txt

# for some reason, single quotes work better
sed -i -e "s/\"/'/g" url.txt

az rest --method get --url "$(cat url.txt)" --query "sort_by(Items, &unitPrice)" -o json > prices.json
