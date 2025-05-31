let leaderId = null;

$(function() {
    window.addEventListener('message', function(event) {
        let data = event.data;
        
        if (data.type === "ui") {
            if (data.status) {
                $("#container").show();
                $("#mission-ui").addClass("active").show();
                $("#invite-ui").removeClass("active").hide();
                
                if (data.missionData) {
                    updateMissionStatus(data.missionData);
                }
            } else {
                $("#container").hide();
                $("#mission-ui").removeClass("active");
                $("#invite-ui").removeClass("active");
            }
        } else if (data.type === "update") {
            if (data.missionData) {
                updateMissionStatus(data.missionData);
            }
        } else if (data.type === "invite") {
            $("#container").show();
            $("#invite-ui").addClass("active").show();
            $("#mission-ui").removeClass("active").hide();
            
            leaderId = data.leaderId;
            $("#inviter-name").text(data.leaderName);
        } else if (data.type === "updateTeam") {
            updateTeamMembers(data.team);
        }
    });
    
    $("#close-btn").click(function() {
        $.post('https://alpha-mission/close', JSON.stringify({}));
    });
    
    $("#start-mission").click(function() {
        $.post('https://alpha-mission/startMission', JSON.stringify({}));
    });
    
    $("#cancel-mission").click(function() {
        $.post('https://alpha-mission/close', JSON.stringify({}));
    });
    
    $("#invite-btn").click(function() {
        const playerId = $("#player-id").val();
        if (playerId) {
            $.post('https://alpha-mission/inviteFriend', JSON.stringify({
                playerId: playerId
            }));
            $("#player-id").val('');
        }
    });
    
    $("#accept-invite").click(function() {
        $.post('https://alpha-mission/acceptInvite', JSON.stringify({
            leaderId: leaderId
        }));
    });
    
    $("#decline-invite").click(function() {
        $.post('https://alpha-mission/declineInvite', JSON.stringify({
            leaderId: leaderId
        }));
    });
    
    $("form").on("submit", function(e) {
        e.preventDefault();
    });
    
    document.onkeyup = function(data) {
        if (data.which == 27) { // ESC key
            $.post('https://alpha-mission/close', JSON.stringify({}));
        }
    };
});

function updateMissionStatus(missionData) {
    $(".status-step").removeClass("active completed");
    
    if (missionData.stage === 0) {
        $("#step1").addClass("active");
    } else if (missionData.stage === 1) {
        $("#step1").addClass("completed");
        $("#step2").addClass("active");
    } else if (missionData.stage === 2) {
        $("#step1, #step2").addClass("completed");
        $("#step3").addClass("active");
    } else if (missionData.stage === 3) {
        $("#step1, #step2, #step3").addClass("completed");
        $("#step4").addClass("active");
    } else if (missionData.stage === 4) {
        $("#step1, #step2, #step3, #step4").addClass("completed");
        $("#step5").addClass("active");
    }
    
    let description = "Deliver a special package for the Big Boss. Be careful, this job is dangerous but pays well.";
    
    switch(missionData.stage) {
        case 1:
            description = "You have the package. Deliver it to the marked location on your map.";
            break;
        case 2:
            description = "Package delivered. Defend yourself against incoming enemies!";
            break;
        case 3:
            description = "You've defeated the enemies. Return to the Big Boss to complete the mission.";
            break;
        case 4:
            description = "Mission completed successfully. Well done!";
            break;
    }
    
    $("#mission-description").text(description);
    
    if (missionData.friends && missionData.friends.length > 0) {
        updateTeamMembers(missionData.friends);
    }
    
    if (missionData.active) {
        $("#start-mission").prop("disabled", true).css("opacity", 0.5);
    } else {
        $("#start-mission").prop("disabled", false).css("opacity", 1);
    }
    
    if (missionData.cooldown) {
        let minutes = Math.floor(missionData.cooldownTime / 60);
        let seconds = missionData.cooldownTime % 60;
        $("#mission-description").text(`Mission on cooldown. Available again in ${minutes}m ${seconds}s.`);
        $("#start-mission").prop("disabled", true).css("opacity", 0.5);
    }
}

function updateTeamMembers(team) {
    $("#team-list").html('<div class="team-member"><div class="member-icon"><i class="fas fa-user"></i></div><div class="member-name">You (Leader)</div></div>');
    
    team.forEach(member => {
        $("#team-list").append(`
            <div class="team-member">
                <div class="member-icon"><i class="fas fa-user-friends"></i></div>
                <div class="member-name">${member.name}</div>
            </div>
        `);
    });
}
