#ifndef YDWETriggerEventIncluded
#define YDWETriggerEventIncluded

//===========================================================================  
//===========================================================================  
//�Զ����¼� 
//===========================================================================
//===========================================================================   

library YDWETriggerEvent 

globals
#ifndef YDWE_DamageEventTrigger
#define YDWE_DamageEventTrigger
    trigger yd_DamageEventTrigger = null
    trigger yd_DamageEventTriggerToDestory = null
#endif
    private constant integer DAMAGE_EVENT_SWAP_TIMEOUT = 600  // ÿ�����ʱ��(��), yd_DamageEventTrigger �ᱻ�������ٶ���
    private constant boolean DAMAGE_EVENT_SWAP_ENABLE = true  // ��Ϊ false ���������ٻ���

    private trigger array DamageEventQueue
    private integer DamageEventNumber = 0
	
    item bj_lastMovedItemInItemSlot = null
	
    private trigger MoveItemEventTrigger = null
    private trigger array MoveItemEventQueue
    private integer MoveItemEventNumber = 0
endglobals
	
//===========================================================================  
//���ⵥλ�˺��¼� 
//===========================================================================
function YDWEAnyUnitDamagedTriggerAction takes nothing returns nothing
    local integer i = 0
    
    loop
        exitwhen i >= DamageEventNumber
        if DamageEventQueue[i] != null and IsTriggerEnabled(DamageEventQueue[i]) and TriggerEvaluate(DamageEventQueue[i]) then
            call TriggerExecute(DamageEventQueue[i])
        endif
        set i = i + 1  
    endloop    
endfunction

function YDWEAnyUnitDamagedFilter takes nothing returns boolean     
    if GetUnitAbilityLevel(GetFilterUnit(), 'Aloc') <= 0 then 
        call TriggerRegisterUnitEvent(yd_DamageEventTrigger, GetFilterUnit(), EVENT_UNIT_DAMAGED)
    endif
    return false
endfunction

function YDWEAnyUnitDamagedEnumUnit takes nothing returns nothing
    local group g = CreateGroup()
    local rect world = GetWorldBounds()
    call GroupEnumUnitsInRect(g, world, Condition(function YDWEAnyUnitDamagedFilter))
    call DestroyGroup(g)
    call RemoveRect(world)
    set g = null
    set world = null
endfunction

function YDWEAnyUnitDamagedRegistTriggerUnitEnter takes nothing returns nothing
    local trigger t = CreateTrigger()
    local region  r = CreateRegion()
    call RegionAddRect(r, GetWorldBounds())
    call TriggerRegisterEnterRegion(t, r, Condition(function YDWEAnyUnitDamagedFilter))
    set r = null
    set t = null
endfunction

// �� yd_DamageEventTrigger �������ٶ���, �Ӷ���й�������¼�
function YDWESyStemAnyUnitDamagedSwap takes nothing returns nothing
    local boolean isEnabled = IsTriggerEnabled(yd_DamageEventTrigger)
    local group g =CreateGroup()

    call DisableTrigger(yd_DamageEventTrigger)
    if yd_DamageEventTriggerToDestory != null then
        call DestroyTrigger(yd_DamageEventTriggerToDestory)
    endif

    set yd_DamageEventTriggerToDestory = yd_DamageEventTrigger
    set yd_DamageEventTrigger = CreateTrigger()
    if not isEnabled then
        call DisableTrigger(yd_DamageEventTrigger)
    endif

    call TriggerAddAction(yd_DamageEventTrigger, function YDWEAnyUnitDamagedTriggerAction) 
    call YDWEAnyUnitDamagedEnumUnit()
endfunction

function YDWESyStemAnyUnitDamagedRegistTrigger takes trigger trg returns nothing
    if trg == null then
        return
    endif
        
    if DamageEventNumber == 0 then
        set yd_DamageEventTrigger = CreateTrigger()
        call TriggerAddAction(yd_DamageEventTrigger, function YDWEAnyUnitDamagedTriggerAction) 
        call YDWEAnyUnitDamagedEnumUnit()
        call YDWEAnyUnitDamagedRegistTriggerUnitEnter()
        if DAMAGE_EVENT_SWAP_ENABLE then
            // ÿ�� DAMAGE_EVENT_SWAP_TIMEOUT ��, ������ʹ�õ� yd_DamageEventTrigger �������ٶ���
            call TimerStart(CreateTimer(), DAMAGE_EVENT_SWAP_TIMEOUT, true, function YDWESyStemAnyUnitDamagedSwap)
        endif
    endif   
    
    set DamageEventQueue[DamageEventNumber] = trg
    set DamageEventNumber = DamageEventNumber + 1
endfunction

//===========================================================================  
//�ƶ���Ʒ�¼� 
//===========================================================================  
function YDWESyStemItemUnmovableTriggerAction takes nothing returns nothing
    local integer i = 0
    
    if GetIssuedOrderId() >= 852002 and GetIssuedOrderId() <= 852007 then 
		set bj_lastMovedItemInItemSlot = GetOrderTargetItem() 
    	loop
        	exitwhen i >= MoveItemEventNumber
        	if MoveItemEventQueue[i] != null and IsTriggerEnabled(MoveItemEventQueue[i]) and TriggerEvaluate(MoveItemEventQueue[i]) then
        	    call TriggerExecute(MoveItemEventQueue[i])
        	endif
        	set i = i + 1  
    	endloop  
	endif	
endfunction

function YDWESyStemItemUnmovableRegistTrigger takes trigger trg returns nothing
    if trg == null then
        return
    endif
        
    if MoveItemEventNumber == 0 then
        set MoveItemEventTrigger = CreateTrigger()
        call TriggerAddAction(MoveItemEventTrigger, function YDWESyStemItemUnmovableTriggerAction) 
        call TriggerRegisterAnyUnitEventBJ(MoveItemEventTrigger, EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER)
    endif   
    
    set MoveItemEventQueue[MoveItemEventNumber] = trg
    set MoveItemEventNumber = MoveItemEventNumber + 1
endfunction

function GetLastMovedItemInItemSlot takes nothing returns item
    return  bj_lastMovedItemInItemSlot
endfunction

endlibrary 

#endif /// YDWETriggerEventIncluded
