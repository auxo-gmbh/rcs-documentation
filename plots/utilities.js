const fs = require("fs");
const extractAmountNodesByDB = db => {
    const parts = db.split('-')
    return parts[1]
};

const extractAlgByDB = db => {
    const parts = db.split('-')
    return parts[0]
};

const getChartCsvFileContent = (header, map) => {
    const csvData =
        Object
            .entries(map)
            .map(([key, value]) => `${key},${value}`)
            .join("\n");
    return `${header}\n${csvData}`;
};

const getCsvFileContent = (header, list) => {
    const csvData =
        list
            .map((value) => `${value}`)
            .join("\n");
    return `${header}\n${csvData}`;
};

const writeBarChartCsvFile = (fileName, nodeValueMap) => {
    const csv = getChartCsvFileContent('nodes,value', nodeValueMap)
    fs.writeFileSync(fileName, csv);
};

const writeTimeChartCsvFile = (fileName, nodeValueMap) => {
    const csv = getChartCsvFileContent('time,value', nodeValueMap)
    fs.writeFileSync(fileName, csv);
};

const writeBoxplotCsvFile = (fileName, valueList) => {
    const csv = getCsvFileContent('value', valueList)
    fs.writeFileSync(fileName, csv);
};

const convertToRelativeTimestampMap = (timestampValueMap) => {
    const timestamps = Object.keys(timestampValueMap).map(timestamp => Number(timestamp));
    const minTimestamp = Math.min(...timestamps)
    const map = {}
    Object
        .entries(timestampValueMap)
        .forEach(([timestamp, value]) => {
            const relativeTimestamp = (timestamp - minTimestamp) / 60000.0
            map[relativeTimestamp] = value
        });
    return map;
}

module.exports = {
    extractAmountNodesByDB,
    extractAlgByDB,
    writeBarChartCsvFile,
    writeTimeChartCsvFile,
    convertToRelativeTimestampMap,
    writeBoxplotCsvFile
};
