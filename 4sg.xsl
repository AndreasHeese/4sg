<?xml version="1.0" encoding="UTF-8"?>
<!-- Copyright 2019-2021 - 4sg.xsl - Small and Simple SVG Sankey Generator - Andreas Heese - Version 1.1 - MIT-License -->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://own.functions" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:map="http://www.w3.org/2005/xpath-functions/map" exclude-result-prefixes="svg xs fn map">
	<xsl:output method="xml" indent="yes" standalone="no" doctype-public="-//W3C//DTD SVG 1.1//EN" doctype-system="http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd" media-type="image/svg" />
	<xsl:decimal-format name="units" decimal-separator="," grouping-separator="."/>
	<xsl:strip-space elements="*"/>
	<!-- ===== default values ===== -->
	<xsl:variable name="defaults" select="map { 
		'font-family':'sans-serif', 
		'font-size':'16',
		'text-color':'black',
		'align':'middle',
		'vertical':'middle',
		'gap':'20',
		'start':'5',
		'end':'5',
		'arrow':'0',
		'padding':'10',
		'box_padding_top':'8',
		'box_padding_bottom':'4',
		'box_width':'250',
		'width':'300',
		'bend':'150',
		'flow_opacity':'0.7',
		'opacity':'1',
		'gradient-stop-from':'20%',
		'gradient-stop-to':'80%',
		'start_startOffset':'1',
		'middle_startOffset':'50',
		'end_startOffset':'99',
		'top_dominant-baseline':'hanging',
		'middle_dominant-baseline':'central',
		'bottom_dominant-baseline':'ideographic',
		'unit':'',
		'unit-pattern':'#.##0',
		'title_y':'10',
		'x':'0',
		'y':'100' }">
	</xsl:variable>
	<xsl:variable name="colors" select="'firebrick','forestgreen','rgb(30,144,255)','#FFD700','rgb(0%,81%,82%)'"/><!-- different formats for color definition are available -->
	<xsl:variable name="value-height">500</xsl:variable><!-- height of the values as coordinates -->
	<!-- ===== initialization ===== -->
	<xsl:variable name="factor" select="$value-height div max(for $p in /root/piles/pile return sum(for $b in $p/box return max((fn:boxsum('from',$b/@id), fn:boxsum('to',$b/@id)))))"/>
	<xsl:variable name="piles" select="/root/piles"/>
	<xsl:variable name="flows" select="/root/flows"/>
	<xsl:variable name="width" select="fn:x(/root/piles/pile[last()]) + fn:get(/root/piles/pile[last()],'width') + number(map:get($defaults,'padding'))"/><!-- overall width -->
	<!-- ===== funktions ===== -->
	<xsl:function name="fn:boxsum"><!-- adds the values ​​of a box with a specific id for the specific side, even when using via -->
		<xsl:param name="attr"/>
		<xsl:param name="id"/>
		<xsl:value-of select="sum($flows/flow[@*[name() = $attr] = $id]/@value) + sum($flows/flow[via/@id = $id]/@value)"/>
	</xsl:function>
	<xsl:function name="fn:boxheight"><!-- determines the total value of the larger side of a box and applies the conversion factor from values ​​to coordinates -->
		<xsl:param name="id"/>
		<xsl:value-of select="max((fn:boxsum('from',$id), fn:boxsum('to',$id))) * $factor"/>
	</xsl:function>
	<xsl:function name="fn:boxheight-before"><!-- determines the height of the previous boxes -->
		<xsl:param name="id"/>
		<xsl:value-of select="sum(for $b in $piles/pile/box[@id = $id]/preceding-sibling::box return fn:boxheight($b/@id)) + sum(for $b in ($piles/pile/box[@id = $id]|$piles/pile/box[@id = $id]/preceding-sibling::box)[preceding-sibling::box] return fn:get($b,'gap'))"/>
	</xsl:function>
	<xsl:function name="fn:x"><!-- read x attribute from ancestor-or-self, if not available process special case, otherwise return default value -->
		<xsl:param name="element"/>
		<xsl:choose>
			<xsl:when test="$element/ancestor-or-self::*[@x]">
				<xsl:value-of select="$element/ancestor-or-self::*[@x][1]/@x"/>
			</xsl:when>
			<xsl:when test="$element/ancestor-or-self::pile">
				<xsl:variable name="p" select="$element/ancestor-or-self::pile/preceding-sibling::pile[1]"/>
				<xsl:value-of select="if ($p) then (fn:x($p) + fn:get($p,'width') + number(map:get($defaults,'width'))) else (number(map:get($defaults,'padding')))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="fn:default($element,'x')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<xsl:function name="fn:y"><!-- read the y attribute of the element, process special cases if not available, otherwise return the default value -->
		<xsl:param name="element"/>
		<xsl:choose>
			<xsl:when test="$element[@y]">
				<xsl:value-of select="$element/@y"/>
			</xsl:when>
			<xsl:when test="$element[self::box]">
				<xsl:value-of select="fn:get($element,'y') + fn:boxheight-before($element/@id)"/>
			</xsl:when>
			<xsl:when test="$element[self::title and parent::pile]"><!-- Pile-Titel etwas oberhalb des Pile -->
				<xsl:value-of select="fn:get($element/parent::pile,'y') - fn:get($element,'padding')"/>
			</xsl:when>
			<xsl:when test="$element[self::text and parent::root]">
				<xsl:value-of select="$value-height + max(for $p in $piles/pile return fn:y($p) + sum(for $b in $p/box[not(1)] return fn:get($b,'gap'))) + sum(for $e in $element|$element/preceding-sibling::text return(fn:get($e,'font-size') * 2)) + number(map:get($defaults,'padding'))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="fn:default($element,'y')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<xsl:function name="fn:get"><!-- read attribute values ​​from ancestor-or-self, process special cases if value doesn't exist, otherwise return default value -->
		<xsl:param name="element"/>
		<xsl:param name="value"/>
		<xsl:choose>
			<!-- elements with matching attributes -->
			<xsl:when test="$element/ancestor-or-self::*[@*[local-name() = $value]]">
				<xsl:value-of select="$element/ancestor-or-self::*[@*[local-name() = $value]][1]/@*[local-name() = $value]"/>
			</xsl:when>
			<!-- box without specified color gets value from the variable $colors -->
			<xsl:when test="($value = 'color') and ($element/local-name() = 'box')">
				<xsl:value-of select="$colors[count($piles/pile[box/@id = $element/@id]/preceding-sibling::pile) mod count($colors) + 1]"/>
			</xsl:when>
			<!-- box, pile and pile title without specified width -->
			<xsl:when test="($value = 'width') and ($element/ancestor-or-self::pile)">
				<xsl:value-of select="map:get($defaults,'box_width')"/>
			</xsl:when>
			<!-- overall width for root/title and root/text -->
			<xsl:when test="($value = 'width') and ($element/parent::root) and (($element/self::title) or ($element/self::text))">
				<xsl:value-of select="$width"/>
			</xsl:when>
			<!-- flow without specified color gets gradient of the adjacent boxes -->
			<xsl:when test="($value = 'color') and ($element/local-name() = 'flow')">
				<xsl:value-of select="'url(#'||translate('g-'||fn:get($piles/pile/box[@id = $element/@from],'color')||'-'||fn:get($piles/pile/box[@id = $element/@to],'color'),',()#','__')||')'"/>
			</xsl:when>
			<!-- get position of flow texts depending on align from default values -->
			<xsl:when test="$value = 'startOffset'">
				<xsl:value-of select="map:get($defaults,concat(fn:get($element,'align'),'_',$value))"/>
			</xsl:when>
			<!-- vertical position of texts directly below root (title and text elements) -->
			<xsl:when test="($value = 'dominant-baseline') and ($element/parent::root) and (($element/self::title) or ($element/self::text))">
				<xsl:text>hanging</xsl:text>
			</xsl:when>
			<!-- vertical position of texts directly below pile (title elements) -->
			<xsl:when test="($value = 'dominant-baseline') and ($element/parent::pile) and ($element/self::title)">
				<xsl:text>ideographic</xsl:text>
			</xsl:when>
			<!-- get vertical position for dominant-baseline depending on vertical attribute from default values -->
			<xsl:when test="($value = 'dominant-baseline')">
				<xsl:value-of select="map:get($defaults,concat(fn:get($element,'vertical'),'_',$value))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="fn:default($element,$value)"/>
			</xsl:otherwise>
		</xsl:choose>		
	</xsl:function>
	<xsl:function name="fn:default"><!-- return existing default value -->
		<xsl:param name="element"/>
		<xsl:param name="value"/>
		<xsl:choose><!-- first element-specific, otherwise general default value -->
			<xsl:when test="map:contains($defaults,concat($element[1]/local-name(),'_',$value))">
				<xsl:value-of select="map:get($defaults,concat($element[1]/local-name(),'_',$value))"/>
			</xsl:when>
			<xsl:when test="map:contains($defaults,$value)">
				<xsl:value-of select="map:get($defaults,$value)"/>
			</xsl:when>
		</xsl:choose>		
	</xsl:function>
	<!-- ===== root template ===== -->
	<xsl:template match="root">
		<xsl:if test="count($piles/pile/box/@id) != count(distinct-values($piles/pile/box/@id))">
			<xsl:message terminate="yes">MESSAGE: TERMINATED box/@id values are not unique</xsl:message>
		</xsl:if>
		<xsl:if test="count($flows/flow[@from and not(@from = $piles/pile/box/@id)]) != 0">
			<xsl:message terminate="yes">MESSAGE: TERMINATED flow/@from values not contained in box/@id</xsl:message>
		</xsl:if>
		<xsl:if test="count($flows/flow[@to and not(@to = $piles/pile/box/@id)]) != 0">
			<xsl:message terminate="yes">MESSAGE: TERMINATED flow/@to values not contained in box/@id</xsl:message>
		</xsl:if>
		<xsl:if test="count($flows/flow/via[@id and not(@id = $piles/pile/box/@id)]) != 0">
			<xsl:message terminate="yes">MESSAGE: TERMINATED flow/via/@id values not contained in box/@id</xsl:message>
		</xsl:if>
		<svg viewBox="0 0 {$width} {$value-height + max(for $p in $piles/pile return fn:y($p) + sum(for $b in $p/box return fn:get($b,'gap'))) + number(map:get($defaults,'padding'))}" preserveAspectRatio="xMidYMin meet">
			<xsl:comment>SVG sankey graphic file generated using 4sg.xsl version 1.1 - conversion factor from values to coordinates is <xsl:value-of select="$factor"/></xsl:comment>
			<title>
				<xsl:value-of select="title"/>
			</title>
			<xsl:if test="/root/flows/flow[not(ancestor-or-self::*/@color)]">
				<xsl:variable name="gradients">
					<xsl:for-each select="/root/flows/flow[not(ancestor-or-self::*/@color)]">
						<xsl:variable name="this" select="."/>
						<gradient from="{fn:get($piles/pile/box[@id = $this/@from],'color')}" to="{fn:get($piles/pile/box[@id = $this/@to],'color')}">
							<xsl:value-of select="translate(fn:get($piles/pile/box[@id = $this/@from],'color')||'-'||fn:get($piles/pile/box[@id = $this/@to],'color'),',()#','__')"/>
						</gradient>
					</xsl:for-each>
				</xsl:variable> 
				<defs>
					<xsl:for-each-group select="$gradients/*" group-by=".">
						<linearGradient id="g-{current-grouping-key()}">
							<stop offset="{fn:get(.,'gradient-stop-from')}" stop-color="{@from}"/>
							<stop offset="{fn:get(.,'gradient-stop-to')}" stop-color="{@to}"/>
						</linearGradient>
					</xsl:for-each-group>
				</defs>
			</xsl:if>
			<xsl:if test="/root/@background-color">
				<rect x="0" y="0" width="{$width}" height="{$value-height + max(for $p in $piles/pile return fn:y($p) + sum(for $b in $p/box return fn:get($b,'gap')))}" style="fill:{/root/@background-color}; fill-opacity:{fn:get(.,'opacity')}; stroke:none;"/>
			</xsl:if>
			<xsl:apply-templates select="flows/flow, piles/pile/box" mode="draw"/>
			<xsl:apply-templates select="flows/flow|flows/flow/text, piles/pile/box, piles/pile/title, text, title"/>
			<xsl:apply-templates select="svg:*"/>
		</svg>
	</xsl:template>
	<!-- ===== create box ===== -->
	<xsl:template match="box[not(@color = 'none')]" mode="draw"><!-- show box only if visible, texts are independent -->
		<rect x="{fn:x(.)}" y="{fn:y(.)}" width="{fn:get(.,'width')}" height="{fn:boxheight(@id)}" style="fill:{fn:get(.,'color')}; fill-opacity:{fn:get(.,'opacity')};"/>
	</xsl:template>
	<!-- ===== create flow ===== -->
	<xsl:template match="flow[@value and @from and @to]" mode="draw"><!-- show path only if the flow is complete and should not just create a gap -->
		<xsl:variable name="this" select="."/>
		<xsl:variable name="boxfrom" select="$piles/pile/box[@id = $this/@from]"/>
		<xsl:variable name="boxto" select="$piles/pile/box[@id = $this/@to]"/>
		<xsl:variable name="ly" select="fn:y($boxfrom) + (sum(preceding-sibling::flow[@from = $this/@from]/@value) * $factor) + (@value * $factor div 2)"/>
		<xsl:variable name="ry" select="fn:y($boxto) + (sum(preceding-sibling::flow[@to = $this/@to]/@value) * $factor) + (@value * $factor div 2)"/>
		
		<xsl:variable name="lx" select="fn:x($boxfrom) + fn:get($boxfrom,'width') + fn:get($this,'arrow')"/>
		<xsl:variable name="rx" select="fn:x($boxto) - fn:get($this,'arrow')"/>
		<xsl:variable name="path">
			<xsl:value-of select="'M '||$lx||','||$ly||' '"/>
			<xsl:value-of select="'L '||$lx + fn:get($this,'start')||','||$ly||' '"/>
			<xsl:value-of select="'C '||$lx + fn:get($this,'start') + fn:get($this,'bend')||','||$ly||' '"/>
			<xsl:for-each select="via">
				<xsl:variable name="id" select="@id"/>
				<xsl:variable name="boxvia" select="$piles/pile/box[@id = $id]"/>
				<xsl:variable name="x" select="fn:x($boxvia)"/>
				<xsl:variable name="y" select="fn:y($boxvia) + sum($this/preceding-sibling::flow[@from = $id]/@value) * $factor + ($this/@value * $factor div 2)"/>
				<xsl:value-of select="$x - fn:get($boxvia,'end') - fn:get($this,'bend')||','||$y||' '"/>
				<xsl:value-of select="$x - fn:get($boxvia,'end')||','||$y||' '"/>
				<xsl:value-of select="'L '||$x + fn:get($boxvia,'width')||','||$y"/>				
				<xsl:value-of select="'L '||$x + fn:get($boxvia,'width') + fn:get($boxvia,'start')||','||$y||' '"/>
				<xsl:value-of select="'C '||$x + fn:get($boxvia,'width') + fn:get($boxvia,'start') + fn:get($this,'bend')||','||$y||' '"/>
			</xsl:for-each>
			<xsl:value-of select="$rx - fn:get($this,'end') - fn:get($this,'bend')||','||$ry||' '"/>
			<xsl:value-of select="$rx - fn:get($this,'end')||','||$ry||' '"/>
			<xsl:value-of select="'L '||$rx||','||$ry"/>
		</xsl:variable>
		<xsl:choose><!-- output as path or rect -->
			<xsl:when test="($ly = $ry) and not(via)"><!-- with a straight horizontal path, gradient backgrounds are not visible, therefore display as rect - no via necessary even if spanning several piles -->
				<rect x="{$lx}" y="{fn:y($boxfrom) + sum(preceding-sibling::flow[@from = $this/@from]/@value) * $factor}" width="{$rx - $lx}" height="{@value * $factor}" style="fill:{fn:get(.,'color')}; fill-opacity:{fn:get(.,'opacity')}; stroke:none;"/> 
				<path id="i-{@from}-{@to}-{position()}" d="M {$lx},{$ly} L {$rx},{$ly}" style="stroke:none; fill:none;"/><!-- for lettering -->
			</xsl:when>
			<xsl:otherwise><!-- path -->
				<path id="i-{@from}-{@to}-{position()}" d="{$path}" style="stroke:{fn:get(.,'color')}; stroke-width:{@value * $factor}; fill:none; stroke-opacity:{fn:get(.,'opacity')}; stroke-linejoin:round;"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="fn:get($this,'arrow') != 0">
			<!-- color must be of flow when defined, but of adjacent boxes when gradient -->
			<xsl:variable name="colorfrom" select="if (ancestor-or-self::*[@color]) then (fn:get(.,'color')) else (fn:get($boxfrom,'color'))"/>
			<xsl:variable name="colorto" select="if (ancestor-or-self::*[@color]) then (fn:get(.,'color')) else (fn:get($boxto,'color'))"/>
			<polygon points="{$lx},{$ly} {$lx - fn:get($this,'arrow')},{$ly - (@value * $factor div 2)} {$lx},{$ly - (@value * $factor div 2)} {$lx},{$ly + (@value * $factor div 2)} {$lx - fn:get($this,'arrow')},{$ly + (@value * $factor div 2)}" style="fill:{$colorfrom}; fill-opacity:{fn:get(.,'opacity')}; stroke:none;"/>
			<polygon points="{$rx},{$ry - (@value * $factor div 2)} {$rx + fn:get($this,'arrow')},{$ry} {$rx},{$ry + (@value * $factor div 2)}" style="fill:{$colorto}; fill-opacity:{fn:get(.,'opacity')}; stroke:none;"/>
		</xsl:if>
	</xsl:template>
	<!-- ===== output texts ===== -->
	<xsl:template match="title|text|box[text()|*]">
		<xsl:variable name="element" select="(ancestor-or-self::box[1]|.)[1]"/>
		<xsl:variable name="x">
			<xsl:choose>
				<xsl:when test="self::text and @x"><!-- text with x value -->
					<xsl:value-of select="@x"/>
				</xsl:when>
				<xsl:when test="fn:get(.,'align') = 'start'">
					<xsl:value-of select="fn:x($element) + number(map:get($defaults,'start'))"/>
				</xsl:when>
				<xsl:when test="fn:get(.,'align') = 'end'">
					<xsl:value-of select="fn:x($element) + fn:get($element,'width') - number(map:get($defaults,'end'))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fn:x($element) + (fn:get($element,'width') div 2)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="y">
			<xsl:choose>
				<xsl:when test="fn:get(.,'vertical') = 'top'">
					<xsl:value-of select="fn:y($element) + fn:get(.,'box_padding_top')"/>
				</xsl:when>
				<xsl:when test="fn:get(.,'vertical') = 'bottom'">
					<xsl:value-of select="fn:y($element) + fn:boxheight(ancestor-or-self::box[1]/@id) - fn:get(.,'box_padding_bottom')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fn:y($element) + (fn:boxheight(ancestor-or-self::box[1]/@id) div 2)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<text x="{$x}" y="{$y}" style="font-family:{fn:get(.,'font-family')}; font-size:{fn:get(.,'font-size')}pt; fill:{fn:get(.,'text-color')};" text-anchor="{fn:get(.,'align')}" dominant-baseline="{fn:get(.,'dominant-baseline')}">
			<xsl:apply-templates select="text()|*[not(self::text)]"/>
		</text>
		<xsl:apply-templates select="text"/>
	</xsl:template>
	<xsl:template match="flow[text()|value]|flow/text">
		<text style="font-family:{fn:get(.,'font-family')}; font-size:{fn:get(.,'font-size')}pt; fill:{fn:get(./text()|.,'text-color')};" text-anchor="{fn:get(.,'align')}" dominant-baseline="{fn:get(.,'dominant-baseline')}">
			<textPath xlink:href="#i-{ancestor-or-self::flow[1]/@from}-{ancestor-or-self::flow[1]/@to}-{count(ancestor-or-self::flow[1]/preceding-sibling::flow)+1}" startOffset="{fn:get(.,'startOffset')}%">
				<xsl:apply-templates select="text()|value"/>
			</textPath>
		</text>
	</xsl:template>
	<!-- ===== output values ===== -->
	<xsl:template match="id[ancestor::box]">
		<xsl:value-of select="ancestor::box[1]/@id"/>
	</xsl:template>
	<xsl:template match="id[ancestor::flow and (@type = 'from' or @type = 'to')]">
		<xsl:variable name="type" select="@type"/>
		<xsl:value-of select="ancestor::flow/[@*[local-name() = $type]]"/>
	</xsl:template>
	<xsl:template match="value[ancestor::flow]">
		<xsl:value-of select="format-number(ancestor::flow[@value][1]/@value,fn:get(.,'unit-pattern'),'units')||fn:get(.,'unit')"/>
	</xsl:template>
	<xsl:template match="value[ancestor::box and (@type = 'from' or @type = 'to')]">
		<xsl:value-of select="format-number(fn:boxsum(@type,ancestor::box[1]/@id),fn:get(.,'unit-pattern'),'units')||fn:get(.,'unit')"/>
	</xsl:template>
	<xsl:template match="value[ancestor::box and not(@type = 'from' or @type = 'to')]">
		<xsl:value-of select="format-number(max((fn:boxsum('from',ancestor::box[1]/@id), fn:boxsum('to',ancestor::box[1]/@id))),fn:get(.,'unit-pattern'),'units')||fn:get(.,'unit')"/>
	</xsl:template>
	<xsl:template match="value[ancestor::pile and not(ancestor::box) and (@type = 'from' or @type = 'to')]">
		<xsl:value-of select="format-number(fn:boxsum(@type,ancestor::pile[1]/box/@id),fn:get(.,'unit-pattern'),'units')||fn:get(.,'unit')"/>
	</xsl:template>
	<xsl:template match="value[ancestor::pile and not(ancestor::box) and not(@type = 'from' or @type = 'to')]">
		<xsl:value-of select="format-number(max((fn:boxsum('from',ancestor::pile[1]/box/@id), fn:boxsum('to',ancestor::pile[1]/box/@id))),fn:get(.,'unit-pattern'),'units')||fn:get(.,'unit')"/>
	</xsl:template>
	<!-- ===== special templates ===== -->
	<xsl:template match="svg:*">
		<xsl:element name="{local-name()}">
			<xsl:copy-of select="@*|text()"/>
			<xsl:apply-templates select="svg:*"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match="*"/>
</xsl:stylesheet>