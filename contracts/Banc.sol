  // SPDX-License-Identifier: MIT
   pragma solidity >=0.4.22 <0.9.0;

  contract Deposit {

  mapping(address => uint) public balanceDeposit;
  mapping(address => uint) public timeDeposit;
  mapping(address => uint) public balanceCredit;
  mapping(address => uint) public timeCredit;

  uint public stepTime = 0.05 hours; // шаг времени для выплаты по кредиту или депозиту
  uint percentDeposit = 12;
  address payable wallet;
  uint percentCredit = 15;
    
  address payable public recipientDeposit; // адрес получателя депозита
  address payable public recipientCredit; // адрес получателя кредита
  address payable public banc;  // адрес банка


  struct Record { // структура для получателя кредита
    address Addr;
    uint256 ID;
    string Name;
    string date;
    uint256 price;
    bool isValue;
    uint256 signatureCount;
    mapping (address => uint256) signatures;
  }

  constructor() public {
    recipientCredit = 0x3945CC4bC05918B82C5D081C4cD953F8F4Ee6821; // адрес заемщика
    banc = 0xDB4338F4dc9751E0Ee1A702f1CdFe4271Fc384a0;  // адрес банка
    recipientDeposit = 0x84C981e614Dbd92aF84615bC907D0Cd97018f44d; // адрес вкладчика
  }

   modifier signOnly {
    require (msg.sender == recipientCredit || msg.sender == banc);
    _;
  }

  mapping (uint256 => Record) public all_records;
  uint256[] public recordsArr;

  event recordCreated(uint256 ID, string testName, string date, uint256 price);
  event recordSigned(uint256 ID, string testName, string date, uint256 price);



  function newRecord (uint256 _ID, string memory _Name, string memory _date, uint256 price) public { // заемщик
    Record storage newrecord = all_records[_ID];
    require(!all_records[_ID].isValue);
    newrecord.Addr = msg.sender;
    newrecord.ID = _ID;
    newrecord.Name = _Name;
    newrecord.date = _date;
    newrecord.price = price;
    newrecord.isValue = true;
    newrecord.signatureCount = 0;
    recordsArr.push(_ID);
    emit recordCreated(newrecord.ID, _Name, _date, price);
  }

  function signRecord(uint256 _ID) signOnly public payable { // подпись банком и заемщиком
    Record storage records = all_records[_ID];
    require(records.signatures[msg.sender]!=1);
    records.signatures[msg.sender]=1;
    records.signatureCount++;
    emit recordSigned(records.ID, records.Name, records.date, records.price);
    if(records.signatureCount == 2) {
      recipientCredit.transfer(address(this).balance);
      balanceCredit[recipientCredit] = balanceCredit[recipientCredit]+address(this).balance;
      timeCredit[recipientCredit] = block.timestamp;
    }
  }

  event Invest(address investor, uint256 amount);
  event Withdraw(address investor, uint256 amount);

   
  modifier userExist() {  // проверка существования клиента
    require(balanceDeposit[msg.sender] > 0, "Client not exist");
    _;
  }

  modifier checkTime() { // выплата процента депозита/кредита только через 5 секутд
    require(block.timestamp>= timeDeposit[msg.sender]+stepTime, "Veri short period of time");
    _;
  }

  function bankAccount() public payable { 
    require(msg.value >= 0.01 ether);
  }

  function setPercentDeposit(uint _percentDeposit) public { // установить процент депозита
    percentDeposit = _percentDeposit;
  }

  function getPercentDeposit() public view returns(uint) {  // узнать процент депозита
    return percentDeposit;
  }

  function setPercentCredit(uint _percentCredit) public { // установить процент кредита
     percentCredit = _percentCredit;
  }

  function getPercentCredit() public view returns(uint) { // узнать процент кредита
    return  percentCredit;
  }

  function deposit() public payable { // открываем депозит
    if (msg.value > 0) {
          balanceDeposit[msg.sender] = balanceDeposit[msg.sender]+msg.value;
      timeDeposit[msg.sender] = block.timestamp;
      emit Invest(msg.sender, msg.value);
    }
  }

  function payoutAmountDeposit() public view returns(uint256) { // считаем процент по депозиту
    uint rate = balanceDeposit[msg.sender]*percentDeposit/100;
    return rate;
  }

  function returnDeposit() public payable { // закрываем депозит
    uint withdrawallAmount = balanceDeposit[msg.sender];
    balanceDeposit[msg.sender] = 0;
    timeDeposit[msg.sender] = 0;
    msg.sender.transfer(withdrawallAmount);
  }


  function collectPercentDeposit() userExist checkTime public { // выплачиваем процент по депозиту
    uint payout = payoutAmountDeposit();
    msg.sender.transfer(payout);
    emit Withdraw(msg.sender, payout); 
  }

  function payoutAmountCredit() public view returns(uint256) { // считаем процент по кредиту 
    uint rate = balanceCredit[msg.sender]*percentCredit/100;
    return rate;
  }

  function returnCredit() public payable { // закрываем кредит
    uint withdrawallAmount = balanceCredit[msg.sender];
    balanceCredit[msg.sender] = 0;
    timeCredit[msg.sender] = 0;
    banc.transfer(withdrawallAmount);
  }


  function collectPercentCredit() userExist checkTime public { // выплачиваем процент по кредиту
    uint payout = payoutAmountCredit();
    banc.transfer(payout);
    emit Withdraw(banc, payout); 
  }
  }
  