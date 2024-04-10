module.exports = (_config, _Ferdium) => {
  let interval = setInterval(() => {
    if (document.getElementById('cu-data-view-item__link_board-shared')) {
      document.getElementById('cu-data-view-item__link_board-shared').click();
      clearInterval(interval);
    }
  }, 500)
};
