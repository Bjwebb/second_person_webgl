
window.onload = ->
    if (location.hash != '#0' && location.hash != '#1')
        alert("Pick a player!");
    
    player_id = location.hash.slice(1)
    other_id = if (player_id == "0") then "1" else "0"
    
    peer = new Peer(player_id, {key: 'bt01ki4in04tpgb9', debug:3})
    other_conn = undefined
    peer.on 'open', ->
        other_conn = peer.connect(other_id)
        setup_other_conn()

    # set the scene size
    WIDTH = window.innerWidth
    HEIGHT = window.innerHeight

    # set some camera attributes
    VIEW_ANGLE = 45
    ASPECT = 1 #Temporary, reset below
    NEAR = 0.1
    FAR = 10000

    PLAYER_RADIUS = 100

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
        new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR)
        ]
    scene = new THREE.Scene()

    # the camera starts at 0,0,0 so pull it back
    cameras[1].position.z = 300
    cameras[2].position.x = 300
    cameras[3].position.y = 1000
    cameras[3].rotation.x = -Math.PI/2

    # start the renderer
    renderer.setSize WIDTH, HEIGHT

    # attach the render-supplied DOM element
    $container.append renderer.domElement

    # create the sphere's material
    colors = [0xCC0000, 0x00CC00, 0x0000CC, 0xCCCC00, 0xCC00CC, 0x00CCCC]

    cubeGeometry = new THREE.CubeGeometry(100, 100, 100)

    for camera,i in cameras
        material = new THREE.MeshLambertMaterial(color:colors[i%colors.length])
        cube = new THREE.Mesh(cubeGeometry, material)
        camera.add cube
        scene.add camera

    wallMaterial = new THREE.MeshLambertMaterial(0xCCCCCC)
    #wallMaterial.side = THREE.DoubleSide
    floor = new THREE.Mesh(new THREE.PlaneGeometry(1000, 1000), wallMaterial)
    floor.rotation.x = -Math.PI/2
    floor.position.y = -100
    scene.add floor
    walls_data = [[[30, -250], [200, -400]],
                  [[250, -30], [80, -30]]]
    walls_vectors = ((new THREE.Vector2(point[0], point[1]) for point in wall) for wall in walls_data)
    walls = []
    for wall_line in walls_vectors
        dir_vec = wall_line[1].clone().sub(wall_line[0])
        mid = wall_line[0].lerp(wall_line[1], 0.5)
        console.log(wall_line, dir_vec)
        console.log(dir_vec.length())

        wall = new THREE.Mesh(new THREE.PlaneGeometry(dir_vec.length(), 500), wallMaterial)
        wall.rotation.y = Math.atan(dir_vec.y / dir_vec.x)
        wall.position.x = mid.x
        wall.position.z = mid.y
        console.log('on and on just another wall in the', wall);
        scene.add wall
        walls.push wall

    # create a point light
    pointLight = new THREE.PointLight(0xFFFFFF)

    # set its position
    pointLight.position.x = 10
    pointLight.position.y = 50
    pointLight.position.z = 130

    # add to the scene
    scene.add pointLight

    animate = ->
      requestAnimationFrame animate
      render()

    render = ->
      views_x = Math.ceil(Math.sqrt(cameras.length))
      views_y = views_x
      view_width = WIDTH/views_x
      view_height = HEIGHT/views_y
      if (has_webgl)
          renderer.enableScissorTest(true)
      for camera,i in cameras
          x = i%views_x
          y = Math.floor(i/views_y)
          camera.aspect = view_width/view_height
          # FIXME don't do this every frame
          camera.updateProjectionMatrix()
          if (has_webgl)
            renderer.setViewport(x*view_width, y*view_height, view_width, view_height)
            renderer.setScissor(x*view_width, y*view_height, view_width, view_height)
          renderer.render scene, camera

    $(document).keydown (event) ->
        camera = cameras[player_id]
        old_position = camera.position.clone()
        old_rotation = camera.rotation.clone()
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
        for wall_line in walls_vectors
            if line_intersects_circ(wall_line[0], wall_line[1], new THREE.Vector2(camera.position.x, camera.position.z), PLAYER_RADIUS)
                console.log('Collision with', wall_line)
                camera.position = old_position
                camera.rotation = old_rotation

        if other_conn
            other_conn.send(
                event: 'move',
                # FIXME
                position_x: cameras[player_id].position.x,
                position_y: cameras[player_id].position.y,
                position_z: cameras[player_id].position.z,
                rotation_x: cameras[player_id].rotation.x,
                rotation_y: cameras[player_id].rotation.y,
                rotation_z: cameras[player_id].rotation.z,
            )

    peer.on('connection', (conn) ->
        other_conn = conn
        setup_other_conn()
    )

    
    # FIXME
    setup_other_conn = ->
        other_conn.on('data', (data) ->
            console.log(data)
            switch data.event
                when 'move'
                    cameras[other_id].position.x = data.position_x
                    cameras[other_id].position.y = data.position_y
                    cameras[other_id].position.z = data.position_z
                    cameras[other_id].rotation.x = data.rotation_x
                    cameras[other_id].rotation.y = data.rotation_y
                    cameras[other_id].rotation.z = data.rotation_z
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
