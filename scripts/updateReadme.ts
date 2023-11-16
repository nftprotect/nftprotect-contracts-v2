import fs from 'fs';

// Читаем файлы
const contractsJson = JSON.parse(fs.readFileSync('contracts.json', 'utf-8'));
let readmeMd = fs.readFileSync('README.md', 'utf-8');

// Генерируем блок контрактов
let contractsBlock = '## Contracts\n';
for (const network in contractsJson) {
  const capitalizedNetwork = network.charAt(0).toUpperCase() + network.slice(1);
  contractsBlock += `### ${capitalizedNetwork}\n`;
  for (const contract in contractsJson[network]) {
    const address = contractsJson[network][contract];
    contractsBlock += `- [${contract}](https://${network}.etherscan.io/address/${address})\n`;
  }
  contractsBlock += '\n';
}

// Проверяем, существует ли уже блок контрактов
const contractsBlockExists = readmeMd.includes('## Contracts');

if (contractsBlockExists) {
  // Заменяем существующий блок контрактов
  const contractsBlockRegex = /## Contracts[\s\S]*?(?=##(?![\s\S]*##)|$)/;
  readmeMd = readmeMd.replace(contractsBlockRegex, contractsBlock);
} else {
  // Добавляем новый блок контрактов
  readmeMd += contractsBlock;
}

// Записываем обновленный README.md
fs.writeFileSync('README.md', readmeMd);