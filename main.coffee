window.onload = ->
    player_id = location.hash.slice(1)
    players = { }
    players[player_id] = undefined
    player_connections = {}
    scores = {}

    peer = new Peer(player_id, {key: 'bt01ki4in04tpgb9', debug:3})

    if player_id != "0"
        other_id = "0"
        player_connections[other_id] = null
        peer.on 'open', ->
            player_connections[other_id] = peer.connect(other_id)
            setup_other_conn(other_id)

    # set the scene size
    WIDTH = window.innerWidth
    HEIGHT = window.innerHeight

    # set some camera attributes
    VIEW_ANGLE = 70
    ASPECT = 1 #Temporary, reset below
    NEAR = 100
    FAR = 10000

    PLAYER_RADIUS = 110

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
    scene = new THREE.Scene()


    # start the renderer
    renderer.setSize WIDTH, HEIGHT

    # attach the render-supplied DOM element
    $container.append '<div style="float:left; font-size: 100px" id="scores"></div>'
    $container.append renderer.domElement

    # create the sphere's material
    colors = [0xCC0000, 0x00CC00, 0x0000CC, 0xCCCC00, 0xCC00CC, 0x00CCCC]

    # the camera starts at 0,0,0 so pull it back
    #cameras[2].position.x = 300
    #cameras[3].rotation.x = -Math.PI/2
    teapotGeometry = new THREE.TeapotGeometry(100, true, true, true, true, true)
    for camera,i in cameras
        color = colors[i%colors.length]
        hex = color.toString(16)
        hex = '000000'.substr(0, 6 - hex.length) + hex
        scores[i] = 0
        $('#scores').append('<span id="score'+i+'" style="color: #'+hex+'">0</div>')

        camera.position.x = 300*(Math.floor(i/2))
        camera.position.z = -900*(i%2)
        camera.rotation.y = Math.PI*(i%2)
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

    animate = ->
      requestAnimationFrame animate
      render()

    render = ->
      views_x = Math.ceil(Math.sqrt(cameras.length))
      views_y = if (views_x-1)*views_x >= cameras.length then views_x-1 else views_x
      view_width = WIDTH/views_x
      view_height = HEIGHT/views_y
      if (has_webgl)
          renderer.enableScissorTest(true)
      for camera,i in cameras
          x = i%views_x
          y = Math.floor(i/views_x)
          camera.aspect = view_width/view_height
          # FIXME don't do this every frame
          camera.updateProjectionMatrix()
          if (has_webgl)
              renderer.setViewport(x*view_width, y*view_height, view_width, view_height)
              renderer.setScissor(x*view_width, y*view_height, view_width, view_height)
          #camera.traverse (object) -> object.visible = false
          renderer.render scene, camera
          #camera.traverse (object) -> object.visible = true

    process_win = (id) ->
        scores[id] += 1
        $('#score'+id).html scores[id]

    process_lose = (id) ->
        scores[id] -= 1
        $('#score'+id).html scores[id]

    $(document).keydown (event) ->
        camera = cameras[player_id]
        old_position = camera.position.clone()
        switch event.which
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
    # the camera starts at 0,0,0 so pull it back
    #cameras[2].position.x = 300
    #cameras[3].rotation.x = -Math.PI/2

        for wall_line in walls_vectors
            if line_intersects_circ(wall_line[0], wall_line[1], new THREE.Vector2(camera.position.x, camera.position.z), PLAYER_RADIUS)
                console.log('Collision with', wall_line)
                camera.position = old_position
        
        for other_id,other_camera of cameras
            if other_id == player_id
                continue

            matrix = new THREE.Matrix4()
            matrix.extractRotation(camera.matrix)
            direction = new THREE.Vector3(0, 0, 1)
            direction.applyMatrix4(matrix)
            if line_intersects_circ(
                    new THREE.Vector2(other_camera.position.x, other_camera.position.z),
                    new THREE.Vector2(other_camera.position.x+200*direction.x, other_camera.position.z+200*direction.z),
                    new THREE.Vector2(camera.position.x, camera.position.z),
                    PLAYER_RADIUS)
                process_win(player_id)
                process_lose(other_id)
            if other_camera.position.clone().sub(camera.position).length() < PLAYER_RADIUS*2
                console.log('Teapot collision')
                camera.position = old_position

        for other_id,player_connection of player_connections
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

    peer.on('connection', (conn) ->
        console.log(conn)
        player_connections[conn.peer] = conn
        setup_other_conn(conn.peer)
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
                        players[k] = v
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
