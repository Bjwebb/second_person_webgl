# set some camera attributes
VIEW_ANGLE = 70
ASPECT = 1 #Temporary, reset below
NEAR = 100
FAR = 10000

PLAYER_RADIUS = 110

window.onload = ->
    player_id_full = location.hash.slice(1)
    id_prefix = player_id_full.split('_')[0]
    player_id = player_id_full.split('_')[1]
    players = { }
    players[player_id] = undefined
    player_connections = {}
    scores = {}
    keyState = {}

    peer = if id_prefix == 'anus' then new Peer(player_id_full, {host: 'localhost', port: 9000, debug:3}) else new Peer(player_id_full, {key: 'bt01ki4in04tpgb9', debug:3})
    console.log peer

    if player_id != "0"
        other_id = "0"
        peer.on 'open', ->
            player_connections[other_id] = peer.connect(id_prefix+'_'+other_id)
            setup_other_conn(other_id)

    # set the scene size
    WIDTH = window.innerWidth
    HEIGHT = window.innerHeight


    # get the DOM element to attach to
    # - assume we've got jQuery to hand
    $container = $("#container")

    # create a WebGL renderer, camera
    # and a scene
    has_webgl = document.createElement('canvas').getContext('webgl')
    renderer = if (has_webgl) then new THREE.WebGLRenderer() else new THREE.CanvasRenderer()
    cameras = [
        new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR),
        new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR),
        new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR),
        new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR),
        new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR),
        new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR)
        ]
    overhead_cam = new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR)
    overhead_cam.position.y = 2000
    overhead_cam.rotation.x = -Math.PI / 2
    scene = new THREE.Scene()


    # start the renderer
    renderer.setSize WIDTH, HEIGHT

    # attach the render-supplied DOM element
    $container.append '<div style="position: absolute; left: 0; font-size: 100px" id="scores"></div>'
    $container.append '<div style="position: absolute; left: 0; top: 200px; font-size: 100px" id="msg"></div>'
    $container.append renderer.domElement

    # create the sphere's material
    colors = [0xCC0000, 0x00CC00, 0x0000CC, 0xCCCC00, 0xCC00CC, 0x00CCCC]
    player_names = ["RED", "GREEN", "BLUE", "YELLOW", "PURPLE", "CYAN"]
    win_msg = "418 - You are a teapot."
    lose_msg = "What?! You think this is a game?"

    # the camera starts at 0,0,0 so pull it back
    #cameras[2].position.x = 300
    #cameras[3].rotation.x = -Math.PI/2
    teapotGeometry = new THREE.TeapotGeometry(100, true, true, true, true, true)
    resetCameraPositions = ->
        for camera,i in cameras
            keyState[i] = { 90:false, 88:false, 37:false, 38:false, 39:false, 40:false }
            camera.position.x = 300*(Math.floor(i/2))
            camera.position.z = -900*(i%2)
            camera.rotation.y = Math.PI*(i%2)
    resetCameraPositions()
    for camera,i in cameras
        color = colors[i%colors.length]
        hex = color.toString(16)
        hex = '000000'.substr(0, 6 - hex.length) + hex
        scores[i] = 0
        $('#scores').append('<span id="score'+i+'" style="color: #'+hex+'">0</div>')

        material = new THREE.MeshLambertMaterial(color:color)
        teapot = new THREE.Mesh(teapotGeometry, material)
        teapot.rotation.y = Math.PI/2
        camera.add teapot
        scene.add camera


    wallMaterial = new THREE.MeshLambertMaterial(0xCCCCCC)
    wallMaterial.side = THREE.DoubleSide
    floor = new THREE.Mesh(new THREE.PlaneGeometry(2000, 2000), wallMaterial)
    floor.rotation.x = -Math.PI/2
    floor.position.y = -100
    scene.add floor
    walls_data = []# [[[30, -250], [200, -400]],
                  #[250, -30], [80, -30]]]
    for i in [0..4] by 1
        walls_data.push([[-150+300*i,-800],[-150+300*i,-1300]])
        walls_data.push([[-150+300*i,-100],[-150+300*i,400]])
    walls_vectors = ((new THREE.Vector2(point[0], point[1]) for point in wall) for wall in walls_data)
    walls = []
    for wall_line in walls_vectors
        dir_vec = wall_line[1].clone().sub(wall_line[0])
        mid = wall_line[0].clone().lerp(wall_line[1], 0.5)
        console.log(wall_line, dir_vec)
        console.log(dir_vec.length())

        wall = new THREE.Mesh(new THREE.PlaneGeometry(dir_vec.length(), 500), wallMaterial)
        wall.rotation.y = - Math.atan(dir_vec.y / dir_vec.x)
        wall.position.x = mid.x
        wall.position.z = mid.y
        console.log('on and on just another wall in the', wall)
        scene.add wall
        walls.push wall

    light = new THREE.PointLight(0xFFFFFF)
    light.position.x = 10
    light.position.y = 50
    light.position.z = 130
    scene.add light
    light2 = new THREE.PointLight(0xFFFFFF)
    light2.position.x = -10
    light2.position.y = 50
    light2.position.z = -130
    scene.add light2

    stop = ->
        # FIMXE duplication
        #keyState[player_id] = { see below }
        for other_id,player_connection of player_connections
            player_connection.send(
                event: 'keyState',
                player_id: player_id,
                player_keyState: { 90:false, 88:false, 37:false, 38:false, 39:false, 40:false }
            )
            player_connection.send(
                event: 'move',
                player_id: player_id,
                # FIXME
                position_x: cameras[player_id].position.x,
                position_y: cameras[player_id].position.y,
                position_z: cameras[player_id].position.z,
                rotation_x: cameras[player_id].rotation.x,
                rotation_y: cameras[player_id].rotation.y,
                rotation_z: cameras[player_id].rotation.z
            )

    animate = ->
        requestAnimationFrame animate

        old_position = cameras[player_id].position.clone()

        for k,camera of cameras
            for code,pressed of keyState[k]
                if pressed
                    code = parseInt(code)
                    switch code
                        when 90 then camera.rotation.y += 0.1
                        when 88 then camera.rotation.y -= 0.1
                        when 37
                            camera.position.x -= 10*Math.cos(camera.rotation.y)
                            camera.position.z += 10*Math.sin(camera.rotation.y)
                        when 38
                            camera.position.x -= 10*Math.sin(camera.rotation.y)
                            camera.position.z -= 10*Math.cos(camera.rotation.y)
                        when 39
                            camera.position.x += 10*Math.cos(camera.rotation.y)
                            camera.position.z -= 10*Math.sin(camera.rotation.y)
                        when 40
                            camera.position.x += 10*Math.sin(camera.rotation.y)
                            camera.position.z += 10*Math.cos(camera.rotation.y)

        camera = cameras[player_id]

        for wall_line in walls_vectors
            if line_intersects_circ(wall_line[0], wall_line[1], new THREE.Vector2(camera.position.x, camera.position.z), PLAYER_RADIUS)
                console.log('Collision with', wall_line)
                camera.position = old_position
                stop()
        
        # FIXME other_id_
        for other_id_,other_camera of cameras
            if other_id_ == player_id
                continue

            if (player_id < other_id_)
                shivver = shivs(camera, other_camera)
                shivved = shivs(other_camera, camera)
                if shivver and shivved
                    process_draw(player_id, other_id_)
                else if shivver
                    process_win(player_id)
                    process_lose(other_id_)
                else if shivved
                    process_win(other_id_)
                    process_lose(player_id)

            if other_camera.position.clone().sub(camera.position).length() < PLAYER_RADIUS*2
                console.log('Teapot collision')
                camera.position = old_position
                stop()

        render()

    render = ->
        views_x = Math.ceil(Math.sqrt(cameras.length))
        views_y = if (views_x-1)*views_x >= cameras.length then views_x-1 else views_x
        view_width = WIDTH/views_x
        view_height = HEIGHT/views_y
        if (has_webgl)
            renderer.enableScissorTest(true)
            for camera,i in cameras
                if i == parseInt(player_id)
                    continue
                x = i%views_x
                y = Math.floor(i/views_x)
                camera.aspect = view_width/view_height
                # FIXME don't do this every frame
                camera.updateProjectionMatrix()
                renderer.setViewport(x*view_width, y*view_height, view_width, view_height)
                renderer.setScissor(x*view_width, y*view_height, view_width, view_height)
                #camera.traverse (object) -> object.visible = false
                renderer.render scene, camera
                #camera.traverse (object) -> object.visible = true
        else
            overhead_cam.aspect = WIDTH/HEIGHT
            overhead_cam.updateProjectionMatrix()
            renderer.render scene, overhead_cam

    process_draw = (id1, id2, remote=false) ->
        resetCameraPositions()
        scores[id1] -= 1
        $('#score'+id1).html scores[id1]
        scores[id2] -= 1
        $('#score'+id2).html scores[id2]
        msg(player_names[id1] + ' drew with ' + player_names[id2])
        if not remote
            for other_id, player_connection of player_connections
                player_connection.send(
                    event: 'draw',
                    id1: id1,
                    id2: id2
                )
        $('#teapour').get(0).currentTime = 0
        $('#teapour').get(0).play()


    process_win = (id, remote=false) ->
        resetCameraPositions()
        scores[id] += 1
        $('#score'+id).html scores[id]
        msg(player_names[id] + ' won')
        if not remote
            for other_id, player_connection of player_connections
                player_connection.send(
                    event: 'win',
                    player_id: id,
                )
        $('#teapour').get(0).currentTime = 0
        $('#teapour').get(0).play()

    process_lose = (id, remote=false) ->
        msg(player_names[id] + ' lost')
        if not remote
            for other_id, player_connection of player_connections
                player_connection.send(
                    event: 'lost',
                    player_id: id,
                )

    $(document).keydown (event) ->
        if event.which of keyState[player_id]
            if not keyState[player_id][event.which]
                keyState[player_id][event.which] = true
                for other_id,player_connection of player_connections
                    player_connection.send(
                        event: 'keyState',
                        player_id: player_id,
                        player_keyState: keyState[player_id]
                    )

    $(document).keyup (event) ->
        if event.which of keyState[player_id]
            keyState[player_id][event.which] = false
            for other_id,player_connection of player_connections
                player_connection.send(
                    event: 'keyState',
                    player_id: player_id,
                    player_keyState: keyState[player_id]
                )
                player_connection.send(
                    event: 'move',
                    player_id: player_id,
                    # FIXME
                    position_x: cameras[player_id].position.x,
                    position_y: cameras[player_id].position.y,
                    position_z: cameras[player_id].position.z,
                    rotation_x: cameras[player_id].rotation.x,
                    rotation_y: cameras[player_id].rotation.y,
                    rotation_z: cameras[player_id].rotation.z
                )

    # the camera starts at 0,0,0 so pull it back
    #cameras[2].position.x = 300
    #cameras[3].rotation.x = -Math.PI/2

    peer.on('connection', (conn) ->
        console.log(conn)
        local_id = conn.peer.split('_')[1]
        player_connections[local_id] = conn
        setup_other_conn(local_id)
    )

    
    # FIXME
    setup_other_conn = (other_id) ->
        player_connections[other_id].on 'open', ->
            player_connections[other_id].send(
                event: 'players',
                players: players
            )
        player_connections[other_id].on('data', (data) ->
            switch data.event
                when 'move'
                    cameras[data.player_id].position.x = data.position_x
                    cameras[data.player_id].position.y = data.position_y
                    cameras[data.player_id].position.z = data.position_z
                    cameras[data.player_id].rotation.x = data.rotation_x
                    cameras[data.player_id].rotation.y = data.rotation_y
                    cameras[data.player_id].rotation.z = data.rotation_z
                when 'players'
                    for k,v of data.players
                        console.log k, player_connections
                        if not (k of player_connections) and player_id != '0'
                            console.log('mooooooo')
                            player_connections[k] = peer.connect(id_prefix+'_'+k)
                            setup_other_conn(k)
                        players[k] = v
                when 'win'
                    process_win(data.player_id, true)
                when 'draw'
                    process_draw(data.id1, data.id2, true)
                when 'lose'
                    process_lose(data.player_id, true)
                when 'keyState'
                    keyState[data.player_id] = data.player_keyState
        )

    # draw!
    animate()

closest_point_on_seg = (seg_a, seg_b, circ_cent) ->
    seg_v = seg_b.clone().sub(seg_a)
    pt_v = circ_cent.clone().sub(seg_a)
    seg_v_unit = seg_v.clone().divideScalar(seg_v.length())
    proj = pt_v.dot(seg_v_unit)
    if proj <= 0
        return seg_a.clone()
    if proj >= seg_v.length()
        return seg_b.clone()
    proj_v = seg_v_unit.clone().multiplyScalar(proj)
    closest = proj_v.clone().add(seg_a)
    return closest

line_intersects_circ = (seg_a, seg_b, circ_cent, r) ->
    circ_cent.clone().sub(closest_point_on_seg(seg_a, seg_b, circ_cent)).length() <= r

shivs = (camera, other_camera) ->
    matrix = new THREE.Matrix4()
    matrix.extractRotation(camera.matrix)
    direction = new THREE.Vector3(0, 0, 1)
    direction.applyMatrix4(matrix)
    return line_intersects_circ(
            new THREE.Vector2(other_camera.position.x, other_camera.position.z),
            new THREE.Vector2(other_camera.position.x+200*direction.x, other_camera.position.z+200*direction.z),
            new THREE.Vector2(camera.position.x, camera.position.z),
            PLAYER_RADIUS)

msg = (str) ->
    $('#msg').append($('<div></div>').html(str).delay(2000).fadeOut(1000, -> $(this).remove()))
