// Dimensions of sunburst.
var width = 800;
var height = 600;
var radius = 300;

// Breadcrumb dimensions: width, height, spacing, width of tip/tail.
var b = {
  w: 75, h: 30, s: 3, t: 10
};

var concepts = d3.map();

// Total size of all segments; we set this later, after loading the data.
var totalSize = 0;

var vis;

var partition = d3.layout.partition()
    .size([2 * Math.PI, radius * radius])
    .value(function(d) { return d.size; });

var arc = d3.svg.arc()
    .startAngle(function(d) { return d.x; })
    .endAngle(function(d) { return d.x + d.dx; })
    .innerRadius(function(d) { return Math.sqrt(d.y); })
    .outerRadius(function(d) { return Math.sqrt(d.y + d.dy); });

$(document).ready(function ()
{
	var colorScale = d3.scale.category20();
	var csv = d3.tsv.parseRows($('#csvData').text());
	var conceptRows = d3.tsv.parseRows($('#conceptsCsv').text());
	for (i = 1; i< conceptRows.length;i++)
	{
		var row = conceptRows[i];
		concepts.set(row[0], { name: row[1], color: colorScale(i / 20) });
	}
	concepts.set('end', { name: 'end', color: '#bbbbbb' });
	concepts.set('truncated', { name: 'truncated', color: '#e0e0e0' })

	vis = d3.select("#chart").append("svg:svg")
			.attr("width", width)
			.attr("height", height)
			.on("mousemove", mouseMove)
			.append("svg:g")
			.attr("id", "container")
			.attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");

	var json = buildHierarchy(csv);
	createVisualization(json);
});

// Main function to draw and set up the visualization, once we have the data.
function createVisualization(json) {

  // Basic setup of page elements.
	initializeInfobox();
  drawLegend();
  d3.select("#togglelegend").on("click", toggleLegend);

  // Bounding circle underneath the sunburst, to make it easier to detect
  // when the mouse leaves the parent g.
  vis.append("svg:circle")
      .attr("r", radius)
      .style("opacity", 0);

  // For efficiency, filter nodes to keep only those large enough to see.
  var nodes = partition.nodes(json)
      .filter(function (d)
      {
      	var length = d.dx * Math.sqrt(d.y + d.dy);
      	return (length > 1.1); // we translate the radians in d.dx into a length so that smaller arcs on the outer edge of the burst will have a chance to appear.
      });

  var path = vis.data([json]).selectAll("path")
      .data(nodes)
      .enter().append("svg:path")
      .attr("display", function(d) { return d.depth ? null : "none"; })
      .attr("d", arc)
      .attr("fill-rule", "evenodd")
      .style("fill", function (d)
      {
      	return concepts.has(d.name) ? concepts.get(d.name).color : null;
      })
      .style("opacity", 1)
      .on("mouseover", mouseover);

  // Add the mouseleave handler to the bounding circle.
  d3.select("#container").on("mouseleave", mouseleave);

  // Get total size of the tree = value of root node from partition.
  totalSize = path.node().__data__.value;
 };

// Fade all but the current sequence, and show it in the breadcrumb trail.
function mouseover(d) {

  var percentage = (100 * d.value / totalSize).toPrecision(3);
  var percentageString = percentage + "%";
  if (percentage < 0.1) {
    percentageString = "< 0.1%";
  }

  d3.select("#percentage")
      .text(percentageString);

  d3.select("#explanation")
      .style("visibility", "")
			.style("opacity", 1);

  var sequenceArray = getAncestors(d);
  updateInfobox(sequenceArray);

  // Fade all the segments.
  d3.selectAll("path")
      .style("opacity", 0.3);

  // Then highlight only those that are an ancestor of the current segment.
  vis.selectAll("path")
      .filter(function(node) {
                return (sequenceArray.indexOf(node) >= 0);
              })
      .style("opacity", 1);
}

// Restore everything to full opacity when moving off the visualization.
function mouseleave(d) {

  // Hide the breadcrumb trail
  d3.select("#infobox")
      .style("visibility", "hidden");

  // Deactivate all segments during transition.
  d3.selectAll("path").on("mouseover", null);

  // Transition each segment to full opacity and then reactivate it.
  d3.selectAll("path")
      .transition()
      .duration(1000)
      .style("opacity", 1)
      .each("end", function() {
              d3.select(this).on("mouseover", mouseover);
            });

  d3.select("#explanation")
      .transition()
      .duration(1000)
//      .style("visibility", "hidden")
			.style("opacity", 0);
}

function mouseMove()
{
	// save selection of infobox so that we can later change it's position
	var infobox = d3.select("#infobox");
	// this returns x,y coordinates of the mouse in relation to our svg canvas
	var coord = d3.mouse(this)
	// now we just position the infobox roughly where our mouse is
	infobox.style("left", coord[0] + 20 + "px");
	infobox.style("top", coord[1] + 20 + "px");
}

// Given a node in a partition layout, return an array of all of its ancestor
// nodes, highest first, but excluding the root.
function getAncestors(node) {
  var path = [];
  var current = node;
  while (current.parent) {
    path.unshift(current);
    current = current.parent;
  }
  return path;
}

function initializeInfobox()
{
	// Add the svg area.
	var infobox = d3.select("#infobox").append("svg:svg")
      .attr("width", "100%")
      .attr("height","100%")
      .attr("id", "infoboxPanel");
}


// Update the infobox to show the current sequence and percentage.
function updateInfobox(nodeArray)
{

	// Dimensions of legend item: width, height, spacing, radius of rounded rect.
	var li = {
		w: 200, h: 22, s: 3, r: 3
	};

	$("#infobox").height((nodeArray.length * (li.h + li.s)) - li.s);

	// Data join; key function combines name and depth (= position in sequence).
	var g = d3.select("#infoboxPanel")
      .selectAll("g")
      .data(nodeArray, function (d) { return d.name + d.depth; });

	// Add svg:g elements for each new node.
	var entering = g.enter().append("svg:g");


	g.attr("transform", function (d, i)
		{
			return "translate(0," + i * (li.h + li.s) + ")";
		});

	g.append("svg:rect")
    .attr("rx", li.r)
    .attr("ry", li.r)
    .attr("width", li.w)
    .attr("height", li.h)
    .style("fill", function (d)
    {
      return concepts.get(d.name).color;
    });

	g.append("svg:text")
		.attr("x", li.r)
		.attr("y", li.h / 2)
		.attr("dy", "0.35em")
		.attr("text-anchor", "left")
		.text(function (d)
		{
			return concepts.get(d.name).name;
		});

	// Remove exiting nodes.
	g.exit().remove();

	d3.select("#infobox")
      .style("visibility", "visible");
}

function drawLegend() {

  // Dimensions of legend item: width, height, spacing, radius of rounded rect.
  var li = {
    w: 160, h: 16, s: 3, r: 3
  };

  var legend = d3.select("#legend").append("svg:svg")
      .attr("width", li.w)
      .attr("height", concepts.entries().length * (li.h + li.s));

  var g = legend.selectAll("g")
      .data(concepts.entries())
      .enter().append("svg:g")
      .attr("transform", function(d, i) {
              return "translate(0," + i * (li.h + li.s) + ")";
           });

  g.append("svg:rect")
      .attr("rx", li.r)
      .attr("ry", li.r)
      .attr("width", li.w)
      .attr("height", li.h)
      .style("fill", function (d)
      {
      	return d.value.color;
      });

  g.append("svg:text")
      .attr("x", li.r)
      .attr("y", li.h / 2)
      .attr("dy", "0.25em")
      .attr("text-anchor", "left")
      .text(function (d)
      {
      	return d.value.name;
      });
}

function toggleLegend() {
  var legend = d3.select("#legend");
  if (legend.style("visibility") == "hidden") {
    legend.style("visibility", "");
  } else {
    legend.style("visibility", "hidden");
  }
}

// Take a 2-column CSV and transform it into a hierarchical structure suitable
// for a partition layout. The first column is a sequence of step names, from
// root to leaf, separated by hyphens. The second column is a count of how
// often that sequence occurred.
function buildHierarchy(csv) {
  var root = {"name": "root", "children": []};
  for (var i = 0; i < csv.length; i++) {
    var sequence = csv[i][0];
    var size = +csv[i][1];
    if (isNaN(size)) { // e.g. if this is a header row
      continue;
    }
		console.log(sequence);
    var parts = sequence.split("-");
    var currentNode = root;
    for (var j = 0; j < parts.length; j++) {
      var children = currentNode["children"];
      var nodeName = parts[j];
      var childNode;
      if (j + 1 < parts.length) {
				// Not yet at the end of the sequence; move down the tree.
				var foundChild = false;
				for (var k = 0; k < children.length; k++) {
					if (children[k]["name"] == nodeName) {
						childNode = children[k];
						foundChild = true;
						break;
					}
				}
				// If we don't already have a child node for this branch, create it.
				if (!foundChild) {
					childNode = {"name": nodeName, "children": []};
					children.push(childNode);
				}
				currentNode = childNode;
      } else {
				// Reached the end of the sequence; create a leaf node.
				childNode = {"name": nodeName, "size": size, "children": []};
				children.push(childNode);
      }
    }
  }
  return root;
};
