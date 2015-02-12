# encoding: ascii-8bit

#--
# Copyright 2013-2015 DataStax, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

require 'spec_helper'


module Cassandra
  module Protocol
    module V1
      describe(Decoder) do
        let(:handler)    { double('handler') }
        let(:decoder)    { Decoder.new(handler, compressor) }

        describe('#<<') do
          let(:protocol_version) { 1 }
          let(:flags)            { 0 }
          let(:stream_id)        { 0 }

          let(:buffer) do
            CqlByteBuffer.new([
              protocol_version,
              flags,
              stream_id,
              opcode,
              body.bytesize
            ].pack('c4N') + body)
          end

          context('without compressor') do
            let(:compressor) { nil }

            it 'decodes split responses correctly' do
              allow(handler).to receive(:complete_request)
              decoder << "\x82\x00\x00\b\x00\x00\x16#"
              decoder << "\x00\x00\x00\x02\x00\x00\x00\x01\x00\x00\x00\x06\x00\x06system\x00\x05local\x00\x04rack\x00\r\x00\vdata_center\x00\r\x00\ahost_id\x00\f\x00\x0Frelease_version\x00\r\x00\x06tokens\x00\"\x00\r\x00\vpartitioner\x00\r\x00\x00\x00\x01\x00\x00\x00\x016\x00\x00\x00\x012\x00\x00\x00\x10Rz>\x8A)\xB7I\xA7\xB9\xF1`*\x19\xB7$\x9F\x00\x00\x00\x052.0.8\x00\x00\x15Z\x01\x00\x00\x14-1011897519510923203\x00\x14-1096847474136043202\x00\x14-1158836742128974020\x00\x14-1170734014298834719\x00\x14-1182769368641717244\x00\x13-123940904353517971\x00\x13-128732576924125288\x00\x14-1317229934898481858\x00\x14-1361518956197482866\x00\x14-1416198231824965734\x00\x14-1419326176044643100\x00\x14-1694350828125301562\x00\x14-1718214811789668067\x00\x14-1755588776520198420\x00\x14-1758326377275148348\x00\x13-199190053455709481\x00\x14-2002112412282835588\x00\x14-2006974350733349502\x00\x14-2230560738774326293\x00\x14-2236907793623058893\x00\x14-2494766062521238450\x00\x14-2518151794678737287\x00\x14-2547723278645130986\x00\x14-2602060305939097834\x00\x14-2644342819690193157\x00\x14-2728592427694543702\x00\x14-2751483299964746266\x00\x14-2775361279860294813\x00\x14-2776543259458821260\x00\x14-2825464643487711728\x00\x14-2955188080987288296\x00\x14-3010803267022128777\x00\x14-3071251155827511690\x00\x13-309873739700155926\x00\x14-3190535250206994004\x00\x14-3270805583202865981\x00\x14-3342164378180270844\x00\x14-3355135068804681431\x00\x14-3421550055953572112\x00\x14-3428313151642723479\x00\x14-3474996466308274101\x00\x14-3574346836656353898\x00\x14-3864650141717364389\x00\x13-394853326432106372\x00\x14-4122966819704604225\x00\x14-4161873051734581080\x00\x14-4242837532342936272\x00\x14-4253913050669402125\x00\x13-459251012061826183\x00\x14-4627332832639369570\x00\x14-4686432201944856261\x00\x14-4699286471681554729\x00\x14-4789068211329811766\x00\x14-4877388527833337349\x00\x14-4902082144986633348\x00\x14-4974238026489761366\x00\x13-511198068657740053\x00\x14-5152259998628926646\x00\x14-5181902019465316892\x00\x14-5283463806781439284\x00\x14-5381081751093424446\x00\x14-5447139054449822597\x00\x14-5582377963365957466\x00\x14-5599918062511174594\x00\x14-5741620308329904226\x00\x14-5766890521092105488\x00\x14-5851999802598320530\x00\x14-5959503247607058669\x00\x13-610312664690744089\x00\x13-616912046405634516\x00\x14-6207205990170382893\x00\x14-6210175954320806150\x00\x14-6279715070866470529\x00\x14-6308512004063020765\x00\x14-6316910091133615108\x00\x14-6327913517625565012\x00\x14-6393003804120593051\x00\x14-6407811052578781437\x00\x14-6486041573253063052\x00\x14-6495421126851134086\x00\x14-6495924041089927926\x00\x14-6547547583927760592\x00\x14-6625454761744387877\x00\x14-6640310411108627260\x00\x14-6829061444319818859\x00\x14-6836277905868200130\x00\x14-6885822449935508478\x00\x14-6888988595105690049\x00\x12-69525457744678877\x00\x14-7039906207043602389\x00\x13-705974404544126836\x00\x14-7114847520110777724\x00\x14-7138844131629802762\x00\x14-7163698356405007967\x00\x14-7212490112236249670\x00\x14-7240479916241570114\x00\x14-7284035834457879675\x00\x14-7295114766883575811\x00\x14-7350240639406203967\x00\x14-7453872473372943415\x00\x14-7456552677608438429\x00\x14-7555983030890637168\x00\x14-7560030813060088354\x00\x14-7773894946334794131\x00\x14-7922692222223815243\x00\x14-7941505230678903236\x00\x14-7996951008543459827\x00\x14-8025292939606007603\x00\x14-8118941458297104270\x00\x14-8307908134694985287\x00\x13-833326180686935557\x00\x14-8402432490961481900\x00\x13-853905651149596564\x00\x13-859816488260685345\x00\x14-8620641464455154982\x00\x14-8695838892852673744\x00\x14-8881517075475030293\x00\x14-9011157711576276878\x00\x14-9097752595349630290\x00\x14-9161917386486828500\x00\x14-9210194645878021639\x00\x13-987067058490876097\x00\x12108052771465197901\x00\x131089122361437557591\x00\x131104714609877128595\x00\x131107683545264997086\x00\x131192498784968988047\x00\x131245716634164075433\x00\x131251797685764054727\x00\x131326334879495221850\x00\x131329510808760730787\x00\x131414024144750227005\x00\x131425034148014845207\x00\x131434794567138365430\x00\x131471299452689142780\x00\x131513780679130324929\x00\x131734302449106545395\x00\x131756099253987961828\x00\x131770392761217430957\x00\x131857335063370609337\x00\x131868966863237820838\x00\x131903455236977468892\x00\x131956387571182710005\x00\x131974075541732951623\x00\x12210844307108873369\x00\x132149059084597250218\x00\x132286836259131092783\x00\x132307927964060284817\x00\x132334363809419460811\x00\x132573755969366278596\x00\x132646714441869671097\x00\x132684200055801256527\x00\x132706804019758029021\x00\x132730626012962266339\x00\x132816834541703408426\x00\x132820446173168729427\x00\x132951012951622496031\x00\x132969255531281514170\x00\x132983954539906480975\x00\x133094552674837225088\x00\x133122948669453574281\x00\x133275424856590934109\x00\x133278650382458898412\x00\x12329042555692499659\x00\x133360493220703475164\x00\x133360839424460603703\x00\x133371448441611138089\x00\x12340937141536043954\x00\x133546429153175384436\x00\x133595735631412183557\x00\x133622200283842531777\x00\x133670575102128421627\x00\x133747140604352572070\x00\x133753698910316946923\x00\x133789017698398646728\x00\x133901258382830429938\x00\x134028817458460462192\x00\x134115268820357810331\x00\x134147833382417253903\x00\x134158297532838776996\x00\x134158481477672193252\x00\x134159523532099449451\x00\x1141799718329768355\x00\x134211137697770213138\x00\x134256348280107555530\x00\x134293405126799584074\x00\x12441904672924294489\x00\x134556539937199523954\x00\x134755897384648777491\x00\x134895106606229966540\x00\x134930471402409740852\x00\x134973826731407800266\x00\x135038020972246332313\x00\x135052247007256481575\x00\x135208693237726765265\x00\x135329867708670419243\x00\x135344582860504295128\x00\x12541347792786593215\x00\x135438825082002355899\x00\x135557913388308561613\x00\x135668588935321218266\x00\x135725146366295173019\x00\x135783116540860506968\x00\x135815035419852130254\x00\x135830651536189005977\x00\x135903175006021543263\x00\x1159560243785224508\x00\x135963725346889060755\x00\x136028107874391541560\x00\x136030031645089336891\x00\x136261353122338882874\x00\x136263396294324654701\x00\x136364270955073782889\x00\x12641505485617423498\x00\x12644834934329406585\x00\x136571525830673553599\x00\x136976299852119393496\x00\x137077794572287778807\x00\x137157812432253529550\x00\x137220106057578622790\x00\x137253223446687069262\x00\x137291975799682068369\x00\x12732239496931538623\x00\x137325619418781920876\x00\x137358077110096730579\x00\x137410921542467647696\x00\x137524382827857368015\x00\x137606765522967685393\x00\x12770532839900156995\x00\x137846827676234058588\x00\x137926602165090144072\x00\x137996364577728533113\x00\x138092452721553842542\x00\x138119358192072559645\x00\x138144162878521813913\x00\x138160507819479397434\x00\x138294501755381822838\x00\x138361934633420450226\x00\x138364617198426432489\x00\x12840376681904620445\x00\x138467794805273126245\x00\x138477966881833333163\x00\x138495616292116969201\x00\x138507212157919145324\x00\x138518789090044349418\x00\x138528438343198541049\x00\x138644613946199055709\x00\x138663089073594022629\x00\x138860092675799580698\x00\x138866537926188232266\x00\x138955580419609116134\x00\x138986289946074146993\x00\x139109510739620149854\x00\x12939455362098484921\x00\x12944690218733078320\x00\x12946479330019965749\x00\x00\x00+org.apache.cassandra.dht.Murmur3Partitioner\x82\x00\x01\b\x00\x00+\xB8\x00\x00\x00\x02\x00\x00\x00\x01\x00\x00\x00\a\x00\x06system\x00\x05peers\x00\x04peer\x00\x10\x00\x04rack\x00\r\x00\vdata_center\x00\r\x00\ahost_id\x00\f\x00\vrpc_address\x00\x10\x00\x0Frelease_version\x00\r\x00\x06tokens\x00\"\x00\r\x00\x00\x00\x02\x00\x00\x00\x04\n\x02\x06A\x00\x00\x00\x016\x00\x00\x00\x012\x00\x00\x00\x10\xFE\xB4\xC6V\xFD\x11MX\xB6\xF3\x02R\xD3\x91\x92\xF6\x00\x00\x00\x04\n\x02\x06A\x00\x00\x00\x052.0.8\x00\x00\x15g\x01\x00\x00\x13-101472185569552832\x00\x14-1022150220587722450\x00\x14-1163117515862886343\x00\x14-1371339199685487457\x00\x14-1389671859059467336\x00\x14-1547324035119969765\x00\x14-1600896347194665724\x00\x14-1606511751008212103\x00\x14-1621486678146233894\x00\x14-1646964155618449150\x00\x14-1706794875573044931\x00\x13-194837045149368840\x00\x14-1978770461272726301\x00\x14-2038334184000949173\x00\x14-2052854026928356840\x00\x14-2170420825808607607\x00\x14-2223223916956034539\x00\x14-2264466653533833328\x00\x14-2372162622668334976\x00\x14-2568719212263224565\x00\x14-2586483973762864338\x00\x14-2596682251503261234\x00\x14-2655699207676444609\x00\x14-2667339986586692754\x00\x14-2771748472418799341\x00\x14-2814821433521289978\x00\x14-2832394189568733826\x00\x14-2964468714328110301\x00\x14-3044109221491903922\x00\x14-3129125829533988818\x00\x13-317693399669529411\x00\x14-3187950409894087430\x00\x14-3255797160477082960\x00\x14-3279855891248089429\x00\x14-3282463542967507336\x00\x13-339513127311214587\x00\x14-3416832356594588481\x00\x14-3444379236491536930\x00\x14-3522928183921522497\x00\x14-3572085006359820570\x00\x14-3655449051296615372\x00\x14-3685967476477619962\x00\x14-3702080573479564304\x00\x14-3748659090532638565\x00\x14-3905905635547780255\x00\x13-390906019802779523\x00\x14-4034621712377307915\x00\x14-4212100655632327734\x00\x14-4335416482845273151\x00\x14-4350975952063545378\x00\x14-4382221492871091036\x00\x14-4486525907163506372\x00\x14-4504467435810458728\x00\x14-4511634752340973445\x00\x14-4577918589383138844\x00\x14-4586966870848363251\x00\x14-4591305248942917232\x00\x14-4640289066905720634\x00\x14-4684339784532858476\x00\x14-4698841348427933005\x00\x14-4727520863201363116\x00\x14-4785317464159874934\x00\x14-4863902352072168757\x00\x14-4929550868493446223\x00\x14-4967194668621431481\x00\x14-5250725392686009622\x00\x14-5268209975596223345\x00\x14-5280820701860353140\x00\x14-5323562752958551690\x00\x14-5355894862494571203\x00\x13-555026134774561410\x00\x14-5566206331482670369\x00\x13-558075990507549424\x00\x14-5642529038236095261\x00\x14-5727206358086296987\x00\x14-5763604033603659909\x00\x14-5880508186119179406\x00\x14-5900517319700350303\x00\x13-590134697576557412\x00\x14-5944054004991204286\x00\x14-6035787877499388374\x00\x14-6057228491595480496\x00\x14-6123139603619875145\x00\x14-6185557263626431440\x00\x14-6185678656750624621\x00\x14-6204816998678514858\x00\x14-6316590362651290045\x00\x14-6522053422240671223\x00\x14-6523229960810985769\x00\x14-6539064753161352252\x00\x14-6603891907325675196\x00\x13-674991393782944595\x00\x14-6936706073178984590\x00\x14-6958543923378538471\x00\x14-7129679622639705037\x00\x14-7165867039450870089\x00\x14-7167393671881593288\x00\x14-7233264469407667530\x00\x13-730089383771486725\x00\x13-732965796077852899\x00\x14-7344221488557903538\x00\x14-7445319156817344791\x00\x14-7483138920710408966\x00\x14-7525827404404093800\x00\x14-7576036128553308565\x00\x14-7660903958635831750\x00\x14-7770905030588084410\x00\x14-7877116775032120448\x00\x14-7923569369167073694\x00\x14-7958877299284557970\x00\x14-7960445193035376365\x00\x14-8082926584128795969\x00\x13-814955325747735856\x00\x14-8243070503452650801\x00\x14-8283023661314475238\x00\x14-8619696363496239411\x00\x14-8664224757652611953\x00\x14-8669450477093952605\x00\x14-8805459640549902661\x00\x14-8838924115201109929\x00\x14-8899019877324196473\x00\x14-8932817014486196587\x00\x14-8948115755364575903\x00\x14-9024953609307829163\x00\x14-9181178742951541019\x00\x14-9188745030984541514\x00\x131001142892665776556\x00\x131019210506905343671\x00\x131045254975515945864\x00\x131110931352766544631\x00\x131169614109538012309\x00\x12125079933846920972\x00\x131305876009750606332\x00\x131357526248492529272\x00\x12136450884750801879\x00\x12137296087798021765\x00\x131398044679348751409\x00\x131410381636183299310\x00\x131471497728303984832\x00\x131560941820073671893\x00\x131639980119416366985\x00\x131648148143384184442\x00\x131653520072110313992\x00\x131703271690501708686\x00\x131764947158436405496\x00\x131825655847656421874\x00\x131918501576370098008\x00\x131974533584749750488\x00\x132146611165730606386\x00\x132222762299520144266\x00\x132361205328197811958\x00\x132426281299567401905\x00\x132466356874423568573\x00\x132573303027561558247\x00\x132629176190886679533\x00\x132701314079684333072\x00\x132735957122047728288\x00\x132903898660294171215\x00\x133091085107301683566\x00\x133202242595226149263\x00\x133226612176961498105\x00\x133237464523666535404\x00\x133251251826068665786\x00\x133288805861156172659\x00\x133340113930142437988\x00\x133493948900778424716\x00\x133550936196032097164\x00\x133588397125159818654\x00\x133628612978429186498\x00\x133631626538025004766\x00\x133689088643565824356\x00\x133719222646573102841\x00\x133745888077571946116\x00\x133766752262036496811\x00\x133790438758805176096\x00\x12379982231199308127\x00\x133805841954467961407\x00\x133964422328745147711\x00\x133965796082231403290\x00\x134017716898749934478\x00\x134086932920622671712\x00\x134156746133182843178\x00\x134184959484332488439\x00\x134304465496194587111\x00\x134348583865096578732\x00\x134747466169859338102\x00\x134759669342570262730\x00\x134804309014188600304\x00\x134807121868755632997\x00\x134837744853981147912\x00\x134865421580357786152\x00\x134980740115092453343\x00\x134989403019904287991\x00\x134990365307585017499\x00\x135058293184060046283\x00\x135105090837395413512\x00\x135171687471526395337\x00\x135208746164624747410\x00\x12539302950784583334\x00\x135506846849693266791\x00\x135516287480283340709\x00\x135530543274879151062\x00\x135584194740898536100\x00\x135622855048401032006\x00\x135701928962655955165\x00\x135874083882760723813\x00\x136041805334651601353\x00\x136060892768075436001\x00\x136201621523036784673\x00\x136292950016057784560\x00\x136320121846820889756\x00\x136454793015474652235\x00\x136475978389915573749\x00\x136527233463009540310\x00\x12652787916994459967\x00\x136743318649930448851\x00\x106813716841653061\x00\x136863851976612723499\x00\x136948409668752574364\x00\x13718040775972724240"
              decoder << "5\x00\x137239733513600461528\x00\x137336379545883591334\x00\x12735630101160195708\x00\x137411816895967930798\x00\x137464886334074395306\x00\x137466736123475237382\x00\x137501826549793577455\x00\x137548724174955156574\x00\x137549566251244296527\x00\x137627694891720196413\x00\x137704547518106604613\x00\x137812953350371987656\x00\x137855968866497835191\x00\x137906730728155288559\x00\x137946434965228385424\x00\x137982883585355719991\x00\x137987557089270867417\x00\x138184709599317714286\x00\x138236664572163868320\x00\x138302866786155378481\x00\x138342246211943475842\x00\x138350818460304966623\x00\x138450578732722978385\x00\x12850429507628394722\x00\x138572625764013354966\x00\x138624263244115103052\x00\x138637454348521434739\x00\x138660853028275864124\x00\x138785692479496557275\x00\x12878607977110902133\x00\x138901729342989277555\x00\x138940861655207122538\x00\x139080454826023760687\x00\x139106632137304597444\x00\x12914752093232764623\x00\x139172042664657762598\x00\x00\x00\x04\n\x02\a\x90\x00\x00\x00\x017\x00\x00\x00\x012\x00\x00\x00\x10-[F\xEAe\xEEB\x10\x9E-V\x9F\xD1\xA5\xB3O\x00\x00\x00\x04\n\x02\a\x90\x00\x00\x00\x052.0.8\x00\x00\x15d\x01\x00\x00\x14-1043908815995768989\x00\x14-1071965496644365555\x00\x14-1221095772992678794\x00\x14-1224872206289202504\x00\x14-1244721554627107807\x00\x13-128649646834173185\x00\x14-1312831641642419759\x00\x14-1388493897341986219\x00\x14-1408319811067469304\x00\x14-1420185706387925117\x00\x14-1990660460521273744\x00\x14-2085226038325134120\x00\x14-2100664016775506118\x00\x14-2205039562619343934\x00\x13-227988587078312372\x00\x14-2302787331327477354\x00\x14-2379518731993427652\x00\x14-2501432180769327616\x00\x13-25033772920247731"
            end

            context('and auth challenge response') do
              let(:opcode) { 0x0e }

              context('with token') do
                let(:body) { "\x00\x00\x00\x0cbingbongpong" }

                it 'decodes with token' do
                  expect(handler).to receive(:complete_request).with(stream_id, an_instance_of(AuthChallengeResponse)) do |_, response|
                    expect(response.token).to eq('bingbongpong')
                  end

                  decoder << buffer
                end
              end

              context('without token') do
                let(:body) { "\xff\xff\xff\xff" }

                it 'decodes without token' do
                  expect(handler).to receive(:complete_request).with(stream_id, an_instance_of(AuthChallengeResponse)) do |_, response|
                    expect(response.token).to be_nil
                  end

                  decoder << buffer
                end
              end
            end

            context('and auth success response') do
              let(:opcode) { 0x10 }

              context('with token') do
                let(:body) { "\x00\x00\x00\x0cbingbongpong" }

                it 'decodes with token' do
                  expect(handler).to receive(:complete_request).with(stream_id, an_instance_of(AuthSuccessResponse)) do |_, response|
                    expect(response.token).to eq('bingbongpong')
                  end

                  decoder << buffer
                end
              end

              context('without token') do
                let(:body) { "\xff\xff\xff\xff" }

                it 'decodes without token' do
                  expect(handler).to receive(:complete_request).with(stream_id, an_instance_of(AuthSuccessResponse)) do |_, response|
                    expect(response.token).to be_nil
                  end

                  decoder << buffer
                end
              end
            end

            context('and authenticate response') do
              let(:opcode) { 0x03 }
              let(:body)   { "\x00\x2forg.apache.cassandra.auth.PasswordAuthenticator" }

              it 'decodes authentication class' do
                expect(handler).to receive(:complete_request).with(stream_id, an_instance_of(AuthenticateResponse)) do |_, response|
                  expect(response.authentication_class).to eq('org.apache.cassandra.auth.PasswordAuthenticator')
                end

                decoder << buffer
              end
            end
          end

          context('with compressor') do
            let(:compressor) { double('compressor') }

            context('and auth challenge response') do
            end
          end
        end
      end
    end
  end
end
