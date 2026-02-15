// script.js
// Handle clicking on Free slots to open dialog
document.querySelectorAll('td.na').forEach(function(cell){
    cell.addEventListener('click', function(){
      document.getElementById('dialog').style.display = 'flex';
    });
  });
  
  // Dialog buttons
  document.getElementById('bookBtn').onclick = function(){
    document.getElementById('dialog').style.display = 'none';
  };
  document.getElementById('advanceBtn').onclick = function(){
    document.getElementById('dialog').style.display = 'none';
    alert('hai');
  };
  
  // Optional: Handle meeting form submission (demo)
  document.getElementById('meetingForm').addEventListener('submit', function(e){
    e.preventDefault();
    alert('Meeting booked! (Demo only)');
  });
